resource "random_id" "postgres" {
  byte_length = 8
}

data "aws_eks_cluster_auth" "cluster_auth" {
  name       = var.eks_name
  depends_on = [var.eks_name]
}

# provider "kubernetes" {
#   host                   = var.eks_endpoint
#   cluster_ca_certificate = var.certificate_authority_data
#   token                  = data.aws_eks_cluster_auth.cluster_auth.token
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     args        = ["eks", "get-token", "--cluster-name", var.eks_name, "--role-arn", var.eks_cluster_role]
#     command     = "aws"
#   }
# }


# provider "helm" {
#   kubernetes {
#     host                   = var.eks_endpoint
#     cluster_ca_certificate = var.certificate_authority_data
#     token                  = data.aws_eks_cluster_auth.cluster_auth.token
#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       args        = ["eks", "get-token", "--cluster-name", var.eks_name, "--role-arn", var.eks_cluster_role]
#       command     = "aws"
#     }
#   }
# }

# data "aws_eks_cluster" "eks_cluster" {
#   name = var.eks_name
#   depends_on = [var.eks_name]
# }

resource "null_resource" "kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks --region ${var.region} update-kubeconfig --name ${var.eks_name}"
  }
  depends_on = [var.eks_name]
}

resource "kubernetes_namespace" "cve_consumer_app_ns" {
  metadata {
    name = "consumer"
    labels = {
      "istio-injection" = "enabled"
    }
  }
  depends_on = [null_resource.kubeconfig]
}

resource "kubernetes_secret" "postgresql" {
  metadata {
    name      = var.postgresql
    namespace = kubernetes_namespace.cve_consumer_app_ns.metadata[0].name
  }

  data = {
    "postgres-password" = random_id.postgres.hex
  }
  depends_on = [null_resource.kubeconfig]
}

resource "helm_release" "postgresql" {
  name       = var.postgresql
  namespace  = kubernetes_namespace.cve_consumer_app_ns.metadata[0].name
  repository = var.bitnami_pg_repo
  chart      = var.postgresql
  version    = var.postgresql_version

  values = [
    <<EOF
    postgresqlUsername: postgres
    postgresqlDatabase: cve
    auth:
      existingSecret: ${kubernetes_secret.postgresql.metadata[0].name}
      existingSecretPasswordKey: "postgres-password"
    volumePermissions:
      enabled: true
    persistence:
      enabled: true
      mountPath: /data
    readinessProbe:
      initialDelaySeconds: 30
      periodSeconds: 10
      timeoutSeconds: 5
      successThreshold: 1
      failureThreshold: 5
    EOF
  ]

  depends_on = [kubernetes_secret.postgresql, null_resource.kubeconfig]
}
#       existingClaim: ${kubernetes_persistent_volume_claim.postgres_db_ebs_pvc.metadata[0].name}
