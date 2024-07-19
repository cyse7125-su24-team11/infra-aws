
data "aws_eks_cluster_auth" "cluster_auth" {
  name = var.eks_name
}

provider "kubernetes" {
  host                   = var.eks_endpoint
  cluster_ca_certificate = var.certificate_authority_data
  token                  = data.aws_eks_cluster_auth.cluster_auth.token
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.eks_name, "--role-arn", var.eks_cluster_role]
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
      args        = ["eks", "get-token", "--cluster-name", var.eks_name, "--role-arn", var.eks_cluster_role]
      command     = "aws"
    }
  }
}

resource "null_resource" "kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks --region ${var.region} update-kubeconfig --name ${var.eks_name}"
  }
  depends_on = [var.eks_name]
}


resource "kubernetes_namespace" "autoscaler_ns" {
  metadata {
    name = var.autoscaler_ns
  }
  depends_on = [null_resource.kubeconfig]
}

resource "helm_release" "cluster_autoscaler" {
  name       = var.autoscaler_name
  repository = var.autoscaler_repo
  chart      = var.autoscaler_chart
  version    = var.autoscaler_version
  repository_username = var.helm_repo_username
  repository_password = var.helm_repo_token
  namespace = kubernetes_namespace.autoscaler_ns.metadata[0].name

  set {
    name  = "caRoleArn"
    value = var.caRoleArn
  }

  set {
    name  = "dockerconfigjson"
    value = jsonencode(var.docker_config_content)
  }
}

