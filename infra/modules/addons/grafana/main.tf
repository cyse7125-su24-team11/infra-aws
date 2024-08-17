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

data "aws_subnets" "public_subnets" {
  filter {
    name   = "tag:kubernetes.io/role/elb"
    values = ["1"]
  }
}

resource "helm_release" "external_dns" {
  name       = "external-dns"
  namespace  = "kube-system"
  chart      = "external-dns"
  repository = "https://charts.bitnami.com/bitnami"
  version    = "8.3.4"

  values = [
    <<EOF
provider: aws
aws:
  region: "us-east-1"
  accessKeyID: "${var.aws_access_key_id}"
  secretAccessKey: "${var.aws_secret_access_key}"
domainFilters:
  - "dev.anibahscsye6225.me"
policy: sync
rbac:
  create: true
serviceAccount:
  create: true
EOF
  ]
}



resource "helm_release" "nginx-controller" {
  name       = "nginx-controller"
  chart      = "nginx-ingress-controller"
  repository = "https://charts.bitnami.com/bitnami"
  version    = "11.3.20"
  create_namespace = true
  values = [
    <<EOF
service:
  type: LoadBalancer  
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-internal: "false" 
    service.beta.kubernetes.io/aws-load-balancer-subnets: "${join(",", data.aws_subnets.public_subnets.ids)}"
EOF
  ]
}

# resource "kubernetes_manifest" "externaldns_sa" {
#   manifest = yamldecode(file("serviceaccount.yaml"))
# }
# resource "kubernetes_manifest" "externaldns_cr" {
#   manifest = yamldecode(file("clusterrole.yaml"))
# }
# resource "kubernetes_manifest" "externaldns_crb" {
#   manifest = yamldecode(file("clusterrolebinding.yaml"))
# }
# resource "kubernetes_manifest" "externaldns_deployment" {
#   manifest = yamldecode(file("externaldns.yaml"))
# }

resource "kubernetes_manifest" "cluster_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-prod"
    }
    spec = {
      acme = {
        email  = "singh.shab@northeastern.edu"
        server = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "letsencrypt-prod"
        }
        solvers = [{
          dns01 = {
            route53 = {
              region = var.region
            }
          }
        }]
      }
    }
  }
}

resource "kubernetes_manifest" "grafana_certificate" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "grafana-tls"
      namespace = "monitoring"
    }
    spec = {
      secretName = var.cert_name
      issuerRef = {
        kind = "ClusterIssuer"
        name = "letsencrypt-prod"
      }
      commonName = "grafana.dev.anibahscsye6225.me"
      dnsNames = [
        "grafana.dev.anibahscsye6225.me"
      ]
    }
  }
}
#         external-dns.alpha.kubernetes.io/hostname: "grafana.dev.anibahscsye6225.me."

resource "helm_release" "grafana" {
  name       = "grafana"
  namespace  = var.namespace
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"

  values = [
    <<EOF
    service:
      type: NodePort
      port: 80
      targetPort: 3000
    ingress:
      enabled: true
      annotations:
        kubernetes.io/ingress.class: nginx
        ingress.kubernetes.io/force-ssl-redirect: "true"
        cert-manager.io/cluster-issuer: "letsencrypt-prod"
        external-dns.alpha.kubernetes.io/ttl: "300"
        external-dns.alpha.kubernetes.io/hostname: "grafana.dev.anibahscsye6225.me."
      hosts:
        - "grafana.dev.anibahscsye6225.me"
      tls:
        - secretName: grafana-tls
          hosts:
            - "grafana.dev.anibahscsye6225.me"
    podAnnotations:
      sidecar.istio.io/inject: "false"
    podDisruptionBudget:
      maxUnavailable: 1
    adminUser: "admin"
    adminPassword: "admin"
    datasources:
      datasources.yaml:
        apiVersion: 1
        datasources:
          - name: Prometheus
            type: prometheus
            url: "http://prometheus-server.${var.namespace}.svc.cluster.local:80"
            access: proxy
            isDefault: true
    resources:
      requests:
        memory: "64Mi"
        cpu: "100m"
      limits:
        memory: "128Mi"
        cpu: "200m"
    dashboardProviders:
      dashboardproviders.yaml:
        apiVersion: 1
        providers:
        - name: 'default'
          orgId: 1
          folder: ''
          type: file
          disableDeletion: false
          editable: true
          options:
            path: /var/lib/grafana/dashboards/default
    dashboards:
      default:
        kafka:
          gnetId: 10122
          revision: 1
          datasource: Prometheus
        postgres:
          gnetId: 9628
          revision: 1
          datasource: Prometheus
        node_exporter:
          gnetId: 1860
          revision: 37
          datasource: Prometheus
        kube_state_metrics:
          gnetId: 13332
          revision: 12
          datasource: Prometheus
    EOF
  ]
  depends_on = [helm_release.external_dns]
  # depends_on = [ kubernetes_manifest.externaldns_cr, kubernetes_manifest.externaldns_crb, kubernetes_manifest.externaldns_deployment, kubernetes_manifest.externaldns_sa ]
}


# resource "kubernetes_manifest" "istio-gateway" {
#   manifest = {
#     apiVersion = "networking.istio.io/v1alpha3"
#     kind       = "Gateway"
#     metadata = {
#       name      = "istio-ingressgateway-public"
#       namespace = "istio-system"
#       # annotations = {
#       #   "external-dns.alpha.kubernetes.io/hostname" = "grafana.dev.anibahscsye6225.me."
#       #   "external-dns.alpha.kubernetes.io/ttl"      = "300"
#       # }
#     }
#     spec = {
#       selector = {
#         istio = "ingressgateway"
#       }
#       servers = [{
#         port = {
#           number   = "${var.grafana_port}"
#           name     = "http"
#           protocol = "HTTP"
#         }
#         hosts = [var.domain]
#         # },
#         # {
#         #   port = {
#         #     number   = 443
#         #     name     = "https"
#         #     protocol = "HTTPS"
#         #   }
#         #   hosts = [var.domain]
#         #   tls = {
#         #     mode           = "SIMPLE"
#         #     credentialName = var.cert_name
#         #   }
#         }
#       ]
#     }
#   }
# }

# resource "kubernetes_manifest" "grafana_virtualservice" {
#   manifest = {
#     apiVersion = "networking.istio.io/v1alpha3"
#     kind       = "VirtualService"
#     metadata = {
#       name      = "grafana-virtualservice"
#       namespace = var.namespace
#     }
#     spec = {
#       hosts = [var.domain]
#       # "grafana.${var.namespace}.svc.cluster.local", 
#       gateways = ["istio-ingressgateway-public"]
#       # tls = [
#       #   {
#       #     match = [
#       #       {
#       #         port     = 443
#       #         sniHosts = [var.domain]
#       #       }
#       #     ]
#       #     route = [
#       #       {
#       #         destination = {
#       #           host = "grafana.${var.namespace}.svc.cluster.local"
#       #           port = {
#       #             number = "${var.grafana_port}"
#       #           }
#       #         }
#       #       }
#       #     ]
#       #   }
#       # ]
#       tcp = [
#         {
#           match = [
#             {
#               port = "${var.grafana_port}"
#             }
#           ]
#           route = [
#             {
#               destination = {
#                 host = "grafana.${var.namespace}.svc.cluster.local"
#                 port = {
#                   number = "${var.grafana_port}"
#                 }
#               }
#             }
#           ]
#         }
#       ]
#       http = [
#         {
#           route = [
#             {
#               destination = {
#                 host = "grafana.${var.namespace}.svc.cluster.local"
#                 port = {
#                   number = "${var.grafana_port}"
#                 }
#               }
#             }
#           ]
#         }
#       ]
#     }
#   }
#   depends_on = [helm_release.grafana]
# }


# resource "kubernetes_manifest" "grafana_serviceentry" {
#   manifest = {
#     apiVersion = "networking.istio.io/v1alpha3"
#     kind       = "ServiceEntry"
#     metadata = {
#       name      = "grafana-serviceentry"
#       namespace = var.namespace
#     }
#     spec = {
#       hosts = [var.domain]
#       # hosts = ["grafana.${var.namespace}.svc.cluster.local"]
#       ports = [
#         {
#           number   = "${var.grafana_port}"
#           name     = "http"
#           protocol = "HTTP"
#         }
#       ]
#       resolution = "DNS"
#       location   = "MESH_EXTERNAL"
#       endpoints = [
#         {
#           address = "grafana.${var.namespace}.svc.cluster.local"
#         }
#       ]
#     }
#   }
#   depends_on = [kubernetes_manifest.grafana_virtualservice]
# }

