variable caRoleArn {}
variable "docker_config_content" {}
variable "eks_endpoint" {}
variable "eks_name" {}
variable "certificate_authority_data" {}
variable "eks_cluster_role" {}
variable "region" {}

variable "node_group" {}
variable "node_group_iam_role" {}
variable "ebs_csi_role" {}
variable "vpc_cni_role" {}
variable "ca_role_arn" {}
variable "kubeconfig" {}
variable "helm_repo_token" {}

variable "private_subnets" {}
variable "public_subnets" {}

variable "autoscaler_ns" {
    default = "eks-ca"
}

variable "autoscaler_name" {
    default = "eks-autoscaler"
}

variable "autoscaler_repo" {
    default = "https://raw.githubusercontent.com/cyse7125-su24-team11/ca-helm-registry/main/"
}

variable "autoscaler_chart" {
    default = "autoscaler"
}

variable "autoscaler_version" {
    default = "0.1.0"
}

variable "helm_repo_username" {
    default = "maheshpoojaryneu"
}