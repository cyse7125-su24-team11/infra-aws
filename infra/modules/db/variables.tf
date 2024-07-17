variable "kubeconfig" {}
variable "region" {}
variable "eks_name" {}
variable "eks_endpoint" {}
variable "certificate_authority_data" {}
variable "eks_cluster_role" {}



variable "postgresql" {
  default = "postgresql"
}
variable "bitnami_pg_repo" {
  default = "https://charts.bitnami.com/bitnami"
}
variable "postgresql_version" {
  default = "15.5.9"
}

variable "postgresql_cm" {
  default = "postgres-config"
}

variable "ebs_sc" {
  default = "ebs-sc"
}