variable "region" {
  type    = string
  default = "us-east-1"
}
variable "eks_cluster_role" {
  type    = string
  default = "eks-cluster-role"
}

variable "eks_pod_identity_role" {
  type    = string
  default = "eks-pod-identity-role"
}

variable "core_dns_role" {
  type    = string
  default = "core-dns-role"
}
variable "kube_proxy_role" {
  type    = string
  default = "kube-proxy-role"
}
variable "vpc_cni_role" {
  type    = string
  default = "vpc-cni-role"
}
variable "node_group_role" {
  type    = string
  default = "node-group-role"
}
variable "ebs_csi_role" {
  type    = string
  default = "ebs-csi-role"
}
variable "ebs_csi_kms_policy" {
  type    = string
  default = "ebs-csi-kms-policy"
}
variable "ebs_csi_custom_policy" {
  type    = string
  default = "ebs-csi-custom-policy"
}
variable "oidc_cert" {}
variable "ebs_kms_key_arn" {}
variable "oidc_provider_url" {}

variable "eks_name" {
  type    = string
  default = "cve-eks"
}