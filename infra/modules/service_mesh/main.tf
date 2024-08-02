data "aws_eks_cluster_auth" "cluster_auth" {
  name = var.eks_name
}

data "aws_eks_cluster" "eks_cluster" {
  name = var.eks_name
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

resource "kubernetes_manifest" "istio-gateway" {
  manifest = {
    apiVersion = "networking.istio.io/v1alpha3"
    kind       = "Gateway"
    metadata = {
      name = "istio-gateway"
      namespace = "istio-system"
    }
    spec = {
      selector = {
        istio = "ingressgateway"
      }
      servers = [{
        port = {
          number   = 80
          name     = "http"
          protocol = "HTTP"
        }
        hosts = ["*"]
      }]
    }
  }
  depends_on = [ helm_release.istio-base, helm_release.istiod, helm_release.istio_ingress ]

}
