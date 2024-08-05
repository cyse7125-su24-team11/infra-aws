variable "eks_name" {
  default = "cve-eks"
}

variable "region" {
  default = "us-east-1"
}

variable "pg_username" {}
variable "pg_password" {}


variable "namespace" {
  default = "monitoring"
}

variable "prometheus_port" {
  default = "9090"
}

variable "grafana_port" {
  default = "3000"
}

variable "node_exporter_port" {
  default = "9101"
}

variable "postgres_port" {
  default = "5432"
}

variable "kafka_broker_port" {
  default = "9094"
}

variable "kafka_exporter_port" {
  default = "9308"
}
