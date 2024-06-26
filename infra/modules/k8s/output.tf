
# output "kafka_ns" {
#   value = kubernetes_namespace.kafka_ns.metadata[0].name
# }

output "cve_consumer_app_ns" {
  value = kubernetes_namespace.cve_consumer_app_ns.metadata[0].name
}

output "cve_processor_job_ns" {
  value = kubernetes_namespace.cve_processor_job_ns.metadata[0].name
}

output "cluster_auth_token" {
  value = data.aws_eks_cluster_auth.cluster_auth.token
}