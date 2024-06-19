module "network" {
  source = "./modules/network"
}

module "eks" {
  source                = "./modules/eks"
  eks_cluster_role      = module.iam.eks_cluster_role
  eks_vpc               = module.network.eks_vpc
  public_subnets        = module.network.public_subnets
  private_subnets       = module.network.private_subnets
  eks_sg                = module.network.eks_sg
  eks_secrets_arn       = module.kms.eks_secrets_arn
  ebs_csi_role          = module.iam.ebs_csi_role
  eks_pod_identity_role = module.iam.eks_pod_identity_role
  node_group_role       = module.iam.node_group_iam_role
  vpc_cni_role          = module.iam.vpc_cni_role
}

module "iam" {
  source            = "./modules/iam"
  oidc_cert         = module.eks.oidc_cert
  ebs_kms_key_arn   = module.kms.ebs_kms_key_arn
  oidc_provider_url = module.eks.oidc_provider_url
}

module "kms" {
  source = "./modules/kms"
}

module "node_group" {
  source                                        = "./modules/node_group"
  eks_cluster                                   = module.eks.eks_cluster
  eks_cluster_name                              = module.eks.eks_cluster_name
  private_subnets                               = module.network.private_subnets
  public_subnets                                = module.network.public_subnets
  node_group_iam_role                           = module.iam.node_group_iam_role
  oidc_provider                                 = module.iam.oidc_provider
  ebs_csi                                       = module.eks.ebs_csi
  node_group_AmazonEKS_CNI_Policy               = module.iam.node_group_AmazonEKS_CNI_Policy
  node_group_AmazonEKSWorkerNodePolicy          = module.iam.node_group_AmazonEKSWorkerNodePolicy
  node_group_AmazonEC2ContainerRegistryReadOnly = module.iam.node_group_AmazonEC2ContainerRegistryReadOnly
}