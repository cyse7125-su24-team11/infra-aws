
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



data "aws_subnets" "private_subnets" {
  filter {
    name   = "tag:kubernetes.io/role/internal-elb"
    values = ["1"]
  }
}

resource "kubernetes_namespace" "istio-ns" {
  metadata {
    name = "istio-system"
  }
}

resource "helm_release" "istio-base" {
    
  name = "istio-service-mesh"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart   = "base"
  version = "1.22.3"
  namespace  = "istio-system"

  # create_namespace = true
  depends_on = [ kubernetes_namespace.istio-ns ]
}

resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  version    = "1.22.3"  # Update to the desired Istio version
  namespace  = "istio-system"
  
  # values = [file("custom-profile.yaml")]
  values = [
    <<EOF
global:
  logAsJson: true
  proxy:
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "500m"
        memory: "1Gi"

EOF
  ]

  depends_on = [ helm_release.istio-base ]

}


resource "helm_release" "istio_ingress" {
  name       = "istio-ingressgateway"
  namespace  = "istio-system"
  chart      = "gateway"
  repository = "https://istio-release.storage.googleapis.com/charts"
  version    = "1.22.3"
  values = [
  <<EOF
annotations:
  service.beta.kubernetes.io/aws-load-balancer-name: "istio-internal-gateway"
  service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
  service.beta.kubernetes.io/aws-load-balancer-internal: "true"
  service.beta.kubernetes.io/aws-load-balancer-subnets: "${join(",", data.aws_subnets.private_subnets.ids)}"
EOF 
  ]
  depends_on = [ helm_release.istio-base, helm_release.istiod ]
}


