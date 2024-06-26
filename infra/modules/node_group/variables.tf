variable "eks_cluster" {}
variable "eks_cluster_name" {}
variable "node_group_iam_role" {}
variable "private_subnets" {}
variable "public_subnets" {}
variable "oidc_provider" {}
variable "ebs_csi" {}

variable "node_group_AmazonEC2ContainerRegistryReadOnly" {}
variable "node_group_AmazonEKSWorkerNodePolicy" {}
variable "node_group_AmazonEKS_CNI_Policy" {}

variable "k8s_version" {
  type    = string
  default = "1.29"
}

variable "ami_type" {
  type    = string
  default = "AL2_x86_64"
}

variable "capacity_type" {
  type    = string
  default = "ON_DEMAND"
}

variable "disk_size" {
  type    = number
  default = 20
}

variable "force_update_version" {
  type    = bool
  default = false
}

variable "instance_types" {
  type    = list(string)
  default = ["c3.large"]
}

variable "desired_size" {
  type    = number
  default = 3
}

variable "max_size" {
  type    = number
  default = 3
}

variable "min_size" {
  type    = number
  default = 3
}

variable "max_unavailable" {
  type    = number
  default = 3
}