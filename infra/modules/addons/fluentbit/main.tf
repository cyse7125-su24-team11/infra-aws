data "aws_eks_cluster_auth" "cluster_auth" {
  name = var.eks_cluster_name
}

provider "kubernetes" {
  host                   = var.eks_endpoint
  cluster_ca_certificate = var.certificate_authority_data
  token                  = data.aws_eks_cluster_auth.cluster_auth.token
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.eks_cluster_name, "--role-arn", var.eks_cluster_role]
    command     = "aws"
  }
}

resource "kubernetes_service_account" "fluentbit" {
  metadata {
    name      = "fluent-bit"
    namespace = "amazon-cloudwatch"
    annotations = {
      "eks.amazonaws.com/role-arn" = var.cloudwatch_role_arn
    }
  }
  automount_service_account_token = true
}

resource "kubernetes_cluster_role" "fluentbit" {
  metadata {
    name = "fluent-bit-role"
  }

  rule {
    api_groups = [""]
    resources  = ["namespaces", "pods"]
    verbs      = ["get", "list", "watch"]
  }
  depends_on = [ kubernetes_service_account.fluentbit ]
}

resource "kubernetes_cluster_role_binding" "fluentbit" {
  metadata {
    name = "fluent-bit-role-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.fluentbit.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.fluentbit.metadata[0].name
    namespace = kubernetes_service_account.fluentbit.metadata[0].namespace
  }
  depends_on = [ kubernetes_cluster_role.fluentbit ]
}

resource "kubernetes_config_map" "fluentbit" {
  metadata {
    name      = "fluent-bit-config"
    namespace = "amazon-cloudwatch"
  }
  data = {
    "fluent-bit.conf" = <<EOF
[SERVICE]
    Flush        1
    Daemon       Off
    Log_Level    info
    Parsers_File parsers.conf
[INPUT]
    Name         tail
    Path         /var/log/containers/*.log
    Parser       docker
    Tag          kube.*
[FILTER]
    Name         kubernetes
    Match        kube.*
    Merge_Log    On
    K8S-Logging.Parser  On
    K8S-Logging.Exclude Off
[OUTPUT]
    Name         cloudwatch_logs
    Match        kube.*
    region       ${var.aws_region}
    log_group_name fluent-bit-cloudwatch
    log_stream_prefix from-fluent-bit-
    auto_create_group true
EOF
    "parsers.conf"    = <<EOF
[PARSER]
    Name        docker
    Format      json
    Time_Key    time
    Time_Format %Y-%m-%dT%H:%M:%S.%L
    Time_Keep   On
    Decode_Field_As   escaped_utf8    log
EOF
  }
  depends_on = [ kubernetes_cluster_role_binding.fluentbit ]
}

resource "kubernetes_daemonset" "fluentbit" {
  metadata {
    name      = "fluent-bit"
    namespace = "amazon-cloudwatch"
    labels = {
      k8s-app = "fluent-bit"
    }
  }

  spec {
    selector {
      match_labels = {
        k8s-app = "fluent-bit"
      }
    }

    template {
      metadata {
        labels = {
          k8s-app = "fluent-bit"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.fluentbit.metadata[0].name

        container {
          name  = "fluent-bit"
          image = "amazon/aws-for-fluent-bit:latest"

          resources {
            limits = {
              memory = "200Mi"
              cpu    = "200m"
            }
            requests = {
              memory = "100Mi"
              cpu    = "100m"
            }
          }

          volume_mount {
            name       = "varlog"
            mount_path = "/var/log"
          }

          volume_mount {
            name       = "config"
            mount_path = "/fluent-bit/etc/fluent-bit.conf"
            sub_path   = "fluent-bit.conf"
          }

          volume_mount {
            name       = "config"
            mount_path = "/fluent-bit/etc/parsers.conf"
            sub_path   = "parsers.conf"
          }
        }

        termination_grace_period_seconds = 30

        volume {
          name = "varlog"
          host_path {
            path = "/var/log"
          }
        }

        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.fluentbit.metadata[0].name
          }
        }
      }
    }
  }
  depends_on = [var.cloudwatch-ns, kubernetes_config_map.fluentbit, kubernetes_service_account.fluentbit]
}


resource "aws_cloudwatch_log_group" "cloudwatch_log_group" {
  name              = "fluent-bit-cloudwatch"
  retention_in_days = 1
}