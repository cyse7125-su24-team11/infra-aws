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


resource "kubernetes_secret" "regcred" {
  metadata {
    name      = "regcred"
    namespace = "kube-system"

    labels = {
      "app.kubernetes.io/managed-by" = "Helm"
    }
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "https://index.docker.io/v1/" = {
          username = var.username
          password = var.password
          auth     = base64encode("${var.username}:${var.password}")
        }
      }
    })
  }
}


resource "helm_release" "metrics_server" {
  name                = var.metrics_server_name
  repository          = var.metrics_server_repo
  chart               = var.metrics_chart
  version             = var.chart_version
  repository_username = var.helm_repo_username
  repository_password = var.helm_repo_token
  namespace           = "kube-system"

  depends_on = [kubernetes_secret.regcred]
  # set {
  #   name  = "dockerconfigjson"
  #   value = jsonencode(var.docker_config_content)
  # }
}

