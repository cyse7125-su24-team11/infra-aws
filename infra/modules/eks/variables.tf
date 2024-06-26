variable "region" {
  type    = string
  default = "us-east-1"
}

variable "k8s_version" {
  type    = string
  default = "1.29"
}

variable "eks_name" {
  type    = string
  default = "cve-eks"
}

variable "eks_authentication_mode" {
  type    = string
  default = "API_AND_CONFIG_MAP"
}

variable "endpoint_private_access" {
  type    = bool
  default = true
}

variable "endpoint_public_access" {
  type    = bool
  default = true
}

variable "kubernetes_network_config" {
  type    = string
  default = "ipv4"
}

variable "enabled_cluster_log_types" {
  type    = list(string)
  default = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "pod_identity_addon_name" {
  type    = string
  default = "eks-pod-identity-agent"
}

variable "pod_identity_addon_version" {
  type    = string
  default = "v1.3.0-eksbuild.1"
}

variable "core_dns_addon_name" {
  type    = string
  default = "coredns"
}

variable "core_dns_addon_version" {
  type    = string
  default = "v1.11.1-eksbuild.9"
}

variable "kube-proxy_addon_name" {
  type    = string
  default = "kube-proxy"
}

variable "kube-proxy_addon_version" {
  type    = string
  default = "v1.29.3-eksbuild.5"
}

variable "vpc_cni_addon_name" {
  type    = string
  default = "vpc-cni"
}

variable "vpc_cni_addon_version" {
  type    = string
  default = "v1.18.2-eksbuild.1"
}

variable "ebs_csi_addon_name" {
  type    = string
  default = "aws-ebs-csi-driver"
}

variable "ebs_csi_addon_version" {
  type    = string
  default = "v1.31.0-eksbuild.1"
}

variable "resolve_conflicts_on_update" {
  type    = string
  default = "PRESERVE"
}

variable "retention_in_days" {
  type    = number
  default = 1
}

variable "eks_cluster_role" {}
variable "ebs_csi_role" {}
variable "vpc_cni_role" {}
variable "eks_pod_identity_role" {}
variable "eks_vpc" {}
variable "public_subnets" {}
variable "private_subnets" {}
variable "eks_sg" {}
variable "eks_secrets_arn" {}
variable "node_group_role" {}
variable "node_group" {}
