output "eks_cluster_role" {
  value = aws_iam_role.eks_cluster_role.arn
}
output "eks_secrets" {
  value = aws_iam_role.eks_cluster_role.arn
}
output "node_group_iam_role" {
  value = aws_iam_role.node_group_role
}
# output "eks_AmazonEKSClusterPolicy" {
#   value = aws_iam_role_policy_attachment.eks_AmazonEKSClusterPolicy
# }
# output "eks_AmazonEKSVPCResourceController" {
#   value = aws_iam_role_policy_attachment.eks_AmazonEKSVPCResourceController
# }
output "ebs_csi_role" {
  value = aws_iam_role.ebs_csi_role
}
output "vpc_cni_role" {
  value = aws_iam_role.vpc_cni_role
}
output "eks_pod_identity_role" {
  value = aws_iam_role.eks_pod_identity_role
}
output "oidc_provider" {
  value = aws_iam_openid_connect_provider.oidc_provider
}



output "node_group_AmazonEKS_CNI_Policy" {
  value = aws_iam_role_policy_attachment.node_group_AmazonEKS_CNI_Policy
}
output "node_group_AmazonEKSWorkerNodePolicy" {
  value = aws_iam_role_policy_attachment.node_group_AmazonEKSWorkerNodePolicy
}
output "node_group_AmazonEC2ContainerRegistryReadOnly" {
  value = aws_iam_role_policy_attachment.node_group_AmazonEC2ContainerRegistryReadOnly
}