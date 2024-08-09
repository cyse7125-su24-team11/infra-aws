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


##########################################
##########   Cert Manager   ##############
##########################################


resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
    # labels = {
    #   "istio-injection" = "enabled"
    # }
  }
  depends_on = [ null_resource.update_kubeconfig ]
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

  set {
    name  = "cainjector.enabled"
    value = "true"
  }

  set {
    name  = "webhook.hostNetwork"
    value = "true"
  }

  set {
    name  = "webhook.service.port"
    value = "9443"
  }

  set {
    name  = "webhook.securePort"
    value = "9445"
  }

  set {
    name  = "cainjector.service.port"
    value = "9444"
  }
  depends_on = [null_resource.update_kubeconfig , kubernetes_namespace.cert_manager]
}
