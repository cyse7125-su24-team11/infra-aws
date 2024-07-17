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