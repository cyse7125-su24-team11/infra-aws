data "aws_eks_cluster_auth" "cluster_auth" {
  name = var.eks_name
}

provider "kubernetes" {
  host                   = var.eks_endpoint
  cluster_ca_certificate = var.certificate_authority_data
  token                  = data.aws_eks_cluster_auth.cluster_auth.token
  # exec {
  #   api_version = "client.authentication.k8s.io/v1beta1"
  #   args        = ["eks", "get-token", "--cluster-name", var.eks_name, "--role-arn", var.eks_cluster_role]
  #   command     = "aws"
  # }
}

resource "null_resource" "kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks --region ${var.region} update-kubeconfig --name ${var.eks_name}"
  }
  depends_on = [var.eks_name]
}

resource "kubernetes_config_map_v1_data" "aws_auth_configmap" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
  force = true
  data = {
    mapRoles = <<YAML
    - rolearn: ${var.node_group_iam_role.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
    - rolearn: ${var.vpc_cni_role.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
    - rolearn: ${var.ebs_csi_role.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
    - rolearn: ${var.ca_role_arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
    - rolearn: ${var.eks_cluster_role}
      username: kubectl-access-user
      groups:
        - system:masters
    YAML
  }
  depends_on = [var.node_group, null_resource.kubeconfig]
}

resource "kubernetes_namespace" "cve_processor_job_ns" {
  metadata {
    name = "producer"
    labels = {
      "istio-injection" = "enabled"
    }
  }
  depends_on = [null_resource.kubeconfig]
}


resource "kubernetes_namespace" "cve_operator" {
  metadata {
    name = "operator"
    labels = {
      "istio-injection" = "enabled"
    }
  }
  depends_on = [null_resource.kubeconfig]
}


##########################################
##########   Cert Manager   ##############
##########################################


resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
    labels = {
      "istio-injection" = "enabled"
    }
  }
}


resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = kubernetes_namespace.cert_manager.metadata[0].name
  version    = "v1.15.1"

  set {
    name  = "crds.enabled"
    value = "true"
  }

  depends_on = [kubernetes_namespace.cert_manager]
}

# data "http" "cwagent_crds" {
#   url = "https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/main/k8s-quickstart/cwagent-custom-resource-definitions.yaml"
# }

# resource "kubernetes_manifest" "cwagent_crds" {
#   manifest = yamldecode(data.http.cwagent_crds.body)
#   depends_on = [helm_release.cert_manager]
# }

# data "http" "cwagent_operator" {
#   url = "https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/main/k8s-quickstart/cwagent-operator-rendered.yaml"
# }

# resource "local_file" "cwagent_operator_template" {
#   content  = chomp(data.http.cwagent_operator.body)
#   filename = "${path.module}/cwagent-operator-rendered.yaml.tpl"
# }

# resource "kubernetes_manifest" "cwagent_operator" {
#   manifest = yamldecode(templatefile("${path.module}/cwagent-operator-rendered.yaml.tpl", {
#     cluster_name = var.eks_name
#     region_name  = var.region
#   }))
# }