
variable "kafka_ns" {
  default = "kafka-ns"
}
# variable "kubeconfig" {}

variable "public_subnet_cidrs" {
  default = ["10.2.4.0/24", "10.2.5.0/24", "10.2.6.0/24"]
}
variable "private_subnet_cidrs" {
  default = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
}


variable "eks_name" {
  default = "cve-eks"
}

variable "region" {
  default = "us-east-1"
}

variable "kafka_secret" {
  type    = string
  default = "kafka-secret"
}

variable "ebs_sc" {
  type    = string
  default = "ebs-sc"
}

variable "ebs_csi_provisioner" {
  type    = string
  default = "ebs.csi.aws.com"
}

variable "ebs_type" {
  type    = string
  default = "gp2"
}

variable "kafka" {
  type    = string
  default = "kafka"
}

variable "kafka_bitnami_repo" {
  type    = string
  default = "https://charts.bitnami.com/bitnami"
}

variable "kafka_bitnami_version" {
  type    = string
  default = "29.3.4"
}

variable "push_cve_records" {
  type    = string
  default = "push-cve-records"
}

variable "topic_replication_factor" {
  default = 3
}

variable "topic_partitions" {
  default = 3
}

variable "topic_cleanup_policy" {
  type    = string
  default = "delete"
}

variable "topic_segment" {
  type    = string
  default = "604800000"
}

variable "topic_retention" {
  type    = string
  default = "604800000"
}
