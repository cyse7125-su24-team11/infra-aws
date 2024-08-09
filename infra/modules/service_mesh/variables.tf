# variable "eks_endpoint" {}
# variable "eks_name" {}
# variable "certificate_authority_data" {}

variable "eks_name" {
  default = "cve-eks"
}
variable "region" {
  default = "us-east-1"
}

variable "eip_tag" {
  default = "tag:instance"
}

variable "grafana_eip" {
  default = "grafana"
}
