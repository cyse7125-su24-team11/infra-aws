# variable "eks_endpoint" {}
# variable "eks_name" {}
# variable "certificate_authority_data" {}

variable "pg_username" {}
variable "pg_password" {}


variable "eks_name" {
  default = "cve-eks"
}

variable "region" {
  default = "us-east-1"
}

variable "namespace" {
  default = "monitoring"
}

variable "prometheus_port" {
  default = "9090"
}

variable "grafana_port" {
  default = "3000"
}

variable "route53_zone_id" {
  default = "Z06075563MFYVGY2N9J1J"
}

variable "domain" {
  default = "grafana.dev.anibahscsye6225.me"
}

variable "aws_access_key_id" {}
variable "aws_secret_access_key" {}
variable "cert_name" {
  default =  "grafana-tls"  
}
