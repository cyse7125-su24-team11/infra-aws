
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

provider "helm" {
  kubernetes {
    host                   = var.eks_endpoint
    cluster_ca_certificate = var.certificate_authority_data
    token                  = data.aws_eks_cluster_auth.cluster_auth.token
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", var.eks_cluster_name, "--role-arn", var.eks_cluster_role]
      command     = "aws"
    }
  }
}

resource "null_resource" "kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks --region ${var.region} update-kubeconfig --name ${var.eks_cluster_name}"
  }
  depends_on = [var.eks_cluster_name]
}



# resource "null_resource" "delete_namespace_if_not_exists" {
#   provisioner "local-exec" {
#     command =  <<-EOT
#       if ! kubectl get namespace amazon-cloudwatch > /dev/null 2>&1; then
#         kubectl delete namespace amazon-cloudwatch
#       fi
#     EOT
#   }
#}

resource "kubernetes_namespace" "cloudwatch-ns" {
  metadata {
    name = "amazon-cloudwatch"
    labels = {
      "istio-injection" = "enabled"
    }
  }
  depends_on = [null_resource.kubeconfig, ] #null_resource.delete_namespace_if_not_exists
}

resource "kubernetes_service_account" "cloudwatch-sa" {
  metadata {
    name      = "cloudwatch"
    namespace = "amazon-cloudwatch"
    annotations = {
      "eks.amazonaws.com/role-arn" = var.cloudwatch_role_arn
    }
  }
  depends_on = [
    var.eks_cluster, var.cloudwatch_role_arn, null_resource.kubeconfig, kubernetes_namespace.cloudwatch-ns
  ]
}


resource "aws_eks_addon" "cloudwatch-observability" {
  cluster_name             = var.eks_cluster_name
  addon_name               = "amazon-cloudwatch-observability"
  addon_version            = "v1.8.0-eksbuild.1"
  service_account_role_arn = var.cloudwatch_role_arn
  resolve_conflicts_on_update        = "OVERWRITE"
  resolve_conflicts_on_create        = "OVERWRITE"
  depends_on = [
    var.eks_cluster, null_resource.kubeconfig, kubernetes_namespace.cloudwatch-ns
  ]
}

# resource "aws_cloudwatch_log_group" "container_insights_application" {
#   name              = "/aws/containerinsights/${var.eks_cluster_name}/application"
#   retention_in_days = 1 
# }

# resource "aws_cloudwatch_log_group" "container_insights_dataplane" {
#   name              = "/aws/containerinsights/${var.eks_cluster_name}/dataplane"
#   retention_in_days = 1
# }

# resource "aws_cloudwatch_log_group" "container_insights_host" {
#   name              = "/aws/containerinsights/${var.eks_cluster_name}/host"
#   retention_in_days = 1
# }
