
data "aws_eks_cluster_auth" "cluster_auth" {
  name = var.eks_name
}


data "aws_eks_cluster" "eks_cluster" {
  name = var.eks_name
}


provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster_auth.token
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.eks_name, "--role-arn", data.aws_eks_cluster.eks_cluster.role_arn]
    command     = "aws"
  }
}


provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks_cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster_auth.token
  }
}
resource "null_resource" "update_kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks --region ${var.region} update-kubeconfig --name ${data.aws_eks_cluster.eks_cluster.name}"
  }
  depends_on = [data.aws_eks_cluster.eks_cluster]
}


resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace
    labels = {
      "istio-injection" = "enabled"
    }
  }
}

resource "kubernetes_network_policy" "allow_all_ingress" {
  metadata {
    name      = "allow-all-ingress"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  spec {
    pod_selector {}

    policy_types = ["Ingress"]

    ingress {
      # Omitting the 'from' field allows all ingress traffic
    }
  }
}

resource "helm_release" "prometheus" {
  name       = "prometheus"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"

  values = [
    <<EOF
    fullnameOverride: prometheus
    podDisruptionBudget:
      enabled: true
      maxUnavailable: 2
    alertmanager:
      enabled: true
    pushgateway:
      enabled: true
    server:
      enabled: true
      service:
        type: ClusterIP
        port:
          name: http
          port: 80
          targetPort: ${var.prometheus_port}
    serverFiles:
      prometheus.yml:
        scrape_configs:
          - job_name: 'kafka_exporter'
            static_configs:
              - targets: ['kafka-exporter-prometheus-kafka-exporter.${var.namespace}.svc.cluster.local:${var.kafka_exporter_port}']
          - job_name: 'postgres_exporter'
            static_configs:
              - targets: ['postgres-exporter-prometheus-postgres-exporter.${var.namespace}.svc.cluster.local:80']
          - job_name: 'kube-state-metrics'
            static_configs:
              - targets: ['kube-state-metrics.${var.namespace}.svc.cluster.local:8080']
          - job_name: 'node-exporter'
            static_configs:
              - targets: ['node-exporter-prometheus-node-exporter.${var.namespace}.svc.cluster.local:${var.node_exporter_port}']
    EOF
  ]
}

resource "helm_release" "prometheus_operator" {
  name       = "prometheus-operator"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  #   version    = "latest"

  values = [
    <<EOF
    alertmanager:
      podDisruptionBudget:
        enabled: true
        minAvailable: 1
    prometheusOperator:
      admissionWebhooks:
        patch:
          podAnnotations:
            sidecar.istio.io/inject: "false"
    prometheus-node-exporter:
      service:
        port: ${var.prometheus_operator_node_exporter_port}
      tolerations:
        - key: "node-role.kubernetes.io/master"
          operator: "Exists"
          effect: "NoSchedule"
      prometheus:
        podDisruptionBudget:
          enabled: true
          minAvailable: 1
        monitor:
          enabled: true
      resources:
        requests:
          memory: "64Mi"
          cpu: "100m"
        limits:
          memory: "128Mi"
          cpu: "200m"
    EOF
  ]
}

variable "prometheus_operator_node_exporter_port" {
  default = 9102
}


resource "helm_release" "kafka_exporter" {
  name       = "kafka-exporter"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-kafka-exporter"
  values = [
    <<EOF
    kafkaServer:
        - "kafka-broker-0-external.kafka-ns.svc.cluster.local:${var.kafka_broker_port}"
    resources:
      requests:
        memory: "64Mi"
        cpu: "100m"
      limits:
        memory: "128Mi"
        cpu: "200m"
    EOF
  ]
}

resource "helm_release" "postgres_exporter" {
  name       = "postgres-exporter"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-postgres-exporter"

  values = [
    <<EOF
    podDisruptionBudget:
      enabled: false
      maxUnavailable: 1
    postgres:
      datasource:
        host: "postgres.consumer"
        port: "${var.postgres_port}"
        user: "${var.pg_username}"
        password: "${var.pg_password}"
        database: "cve"
    resources:
      requests:
        memory: "64Mi"
        cpu: "100m"
      limits:
        memory: "128Mi"
        cpu: "200m"
    EOF
  ]
}

resource "helm_release" "kube_state_metrics" {
  name       = "kube-state-metrics"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-state-metrics"
  values = [
    <<EOF
podAnnotations:
  sidecar.istio.io/inject: "false"
podDisruptionBudget:
  maxUnavailable: 1
resources:
  requests:
    memory: "64Mi"
    cpu: "100m"
  limits:
    memory: "128Mi"
    cpu: "200m"
    EOF
  ]
}

resource "helm_release" "node_exporter" {
  name       = "node-exporter"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-node-exporter"

  values = [
    <<EOF
    tolerations:
      - key: "node-role.kubernetes.io/master"
        operator: "Exists"
        effect: "NoSchedule"

    service:
      port: ${var.node_exporter_port}
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "${var.node_exporter_port}"

    # Set additional values if necessary
    resources:
      requests:
        memory: "64Mi"
        cpu: "100m"
      limits:
        memory: "128Mi"
        cpu: "200m"
    prometheus:
      monitor:
        enabled: true
    EOF
  ]
}

resource "kubernetes_manifest" "prometheus_virtualservice" {
  manifest = {
    apiVersion = "networking.istio.io/v1alpha3"
    kind       = "VirtualService"
    metadata = {
      name      = "prometheus-virtualservice"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
    }
    spec = {
      hosts = ["prometheus-server.${var.namespace}.svc.cluster.local"]
      tcp = [
        {
          match = [
            {
              port = "${var.prometheus_port}"
            }
          ]
          route = [
            {
              destination = {
                host = "prometheus-server.${var.namespace}.svc.cluster.local"
                port = {
                  number = "${var.prometheus_port}"
                }
              }
            }
          ]
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "prometheus_serviceentry" {
  manifest = {
    apiVersion = "networking.istio.io/v1alpha3"
    kind       = "ServiceEntry"
    metadata = {
      name      = "prometheus-serviceentry"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
    }
    spec = {
      hosts = ["prometheus.${var.namespace}.svc.cluster.local"]
      ports = [
        {
          number   = "${var.prometheus_port}"
          name     = "http"
          protocol = "HTTP"
        }
      ]
      resolution = "DNS"
      location   = "MESH_INTERNAL"
      endpoints = [
        {
          address = "prometheus.${var.namespace}.svc.cluster.local"
        }
      ]
    }
  }
}