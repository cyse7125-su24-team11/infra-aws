resource "aws_eks_node_group" "node_group" {
  version         = var.k8s_version
  cluster_name    = var.eks_cluster_name
  node_group_name = "${var.eks_cluster_name}-node-group"

  node_role_arn = var.node_group_iam_role.arn
  count         = length(var.public_subnets)
  subnet_ids = [
    var.public_subnets[0].id,
    var.public_subnets[1].id,
    var.public_subnets[2].id,
    var.private_subnets[0].id,
    var.private_subnets[1].id,
    var.private_subnets[2].id
  ]

  ami_type             = var.ami_type
  capacity_type        = var.capacity_type
  disk_size            = var.disk_size
  force_update_version = var.force_update_version
  instance_types       = var.instance_types # c3.large

  labels = {
    role = "${var.eks_cluster_name}-node-group-role",
    name = "${var.eks_cluster_name}-node-group"
  }

  # Configuration block - should be dynamic values
  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  update_config {
    max_unavailable = var.max_unavailable
  }

  tags = {
    "k8s.io/cluster-autoscaler/${var.eks_cluster_name}" = "owned",
    "k8s.io/cluster-autoscaler/enabled"                 = true
  }
  depends_on = [var.eks_cluster, var.oidc_provider, var.node_group_AmazonEKS_CNI_Policy,
  var.node_group_AmazonEKSWorkerNodePolicy, var.node_group_AmazonEC2ContainerRegistryReadOnly]
  # , var.ebs_csi
}