resource "random_id" "postgres" {
  byte_length = 8
}

resource "kubernetes_secret" "postgresql" {
  metadata {
    name      = var.postgresql
    namespace = var.cve_consumer_app_ns
  }
 
  data = {
    "postgres-password" = random_id.postgres.hex
  }
  depends_on = [ var.kubeconfig ]
}

# resource "kubernetes_persistent_volume_claim" "postgres_db_ebs_pvc" {
#   metadata {
#     name      = "postgres-db-ebs-pvc"
#     namespace = var.cve_consumer_app_ns
#   }

#   spec {
#     access_modes = ["ReadWriteOnce"]
#     resources {
#       requests {
#         memory = "10Gi"
#       }
#     }
#     storage_class_name = var.ebs_sc
#   }
#   depends_on = [var.kubeconfig]
# }

resource "helm_release" "postgresql" {
  name       = var.postgresql
  namespace  = var.cve_consumer_app_ns
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

  depends_on = [kubernetes_secret.postgresql, var.kubeconfig]
}
#       existingClaim: ${kubernetes_persistent_volume_claim.postgres_db_ebs_pvc.metadata[0].name}
