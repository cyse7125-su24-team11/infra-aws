module "kms" {
  source = "./modules/kms"
}

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
  node_group            = module.node_group.node_group
  vpc_cni_role          = module.iam.vpc_cni_role
}

module "iam" {
  source            = "./modules/iam"
  oidc_cert         = module.eks.oidc_cert
  ebs_kms_key_arn   = module.kms.ebs_kms_key_arn
  oidc_provider_url = module.eks.oidc_provider_url
}

module "node_group" {
  source                                           = "./modules/node_group"
  eks_cluster                                      = module.eks.cluster
  eks_cluster_name                                 = module.eks.eks_cluster_name
  private_subnets                                  = module.network.private_subnets
  public_subnets                                   = module.network.public_subnets
  node_group_iam_role                              = module.iam.node_group_iam_role
  oidc_provider                                    = module.iam.oidc_provider
  ebs_csi                                          = module.eks.ebs_csi
  node_group_AmazonEKS_CNI_IAM                     = module.iam.node_group_AmazonEKS_CNI_Policy
  node_group_AmazonEKSWorkerNodeIAM                = module.iam.node_group_AmazonEKSWorkerNodePolicy
  node_group_AmazonEC2ContainerRegistryReadOnlyIAM = module.iam.node_group_AmazonEC2ContainerRegistryReadOnly
  eks_sg                                           = module.network.eks_sg
}

module "k8s" {
  source                     = "./modules/k8s"
  eks_cluster_role           = module.iam.eks_cluster_role
  ebs_csi_role               = module.iam.ebs_csi_role
  vpc_cni_role               = module.iam.vpc_cni_role
  ca_role_arn                = module.iam.caRoleArn
  node_group_iam_role        = module.iam.node_group_iam_role
  node_group                 = module.node_group.node_group
  kubeconfig                 = module.eks.kubeconfig
  region                     = var.region
  eks_endpoint               = module.eks.cluster.endpoint
  eks_name                   = module.eks.cluster.name
  eks_cluster                = module.eks.cluster
  certificate_authority_data = base64decode(module.eks.cluster.certificate_authority.0.data)
}

module "ca" {
  source                     = "./modules/ca"
  caRoleArn                  = module.iam.caRoleArn
  eks_name                   = module.eks.cluster.name
  region                     = var.region
  eks_cluster_role           = module.iam.eks_cluster_role
  eks_endpoint               = module.eks.cluster.endpoint
  ebs_csi_role               = module.iam.ebs_csi_role
  vpc_cni_role               = module.iam.vpc_cni_role
  ca_role_arn                = module.iam.caRoleArn
  node_group_iam_role        = module.iam.node_group_iam_role
  node_group                 = module.node_group.node_group
  kubeconfig                 = module.eks.kubeconfig
  certificate_authority_data = base64decode(module.eks.cluster.certificate_authority.0.data)
  helm_repo_token            = var.helm_repo_token
  private_subnets            = module.network.private_subnets
  public_subnets             = module.network.public_subnets
  username                   = var.username
  password                   = var.password
}


module "cloudwatch-observability" {
  source                     = "./modules/addons/cloudwatch"
  eks_cluster_name           = module.eks.cluster.name
  cloudwatch_role_arn        = module.iam.cloudwatch_role_arn
  eks_cluster                = module.eks.cluster
  region                     = var.region
  eks_cluster_role           = module.iam.eks_cluster_role
  eks_endpoint               = module.eks.cluster.endpoint
  certificate_authority_data = base64decode(module.eks.cluster.certificate_authority.0.data)
}

module "fluentbit" {
  source                     = "./modules/addons/fluentbit"
  aws_region                 = var.region
  cloudwatch_role_arn        = module.iam.cloudwatch_role_arn
  cloudwatch-ns              = module.cloudwatch-observability.cloudwatch-ns
  eks_cluster_name           = module.eks.cluster.name
  eks_endpoint               = module.eks.cluster.endpoint
  certificate_authority_data = base64decode(module.eks.cluster.certificate_authority.0.data)
  eks_cluster_role           = module.iam.eks_cluster_role
}

module "metrics-server" {
  source                     = "./modules/addons/metrics-server"
  username                   = var.username
  password                   = var.password
  helm_repo_token            = var.helm_repo_token
  eks_cluster_name           = module.eks.cluster.name
  eks_endpoint               = module.eks.cluster.endpoint
  certificate_authority_data = base64decode(module.eks.cluster.certificate_authority.0.data)
  eks_cluster_role           = module.iam.eks_cluster_role
}


#############################################################
##--------------- To be deployed separately ---------------##
#############################################################

# Istio
#
# module "istio" {
#   source                     = "./modules/service_mesh"
#   eks_name                   = module.eks.cluster.name
#   eks_endpoint               = module.eks.cluster.endpoint
#   certificate_authority_data = base64decode(module.eks.cluster.certificate_authority.0.data)
#   # eks_cluster_role           = module.iam.eks_cluster_role
#   # eks_cluster_name           = module.eks.cluster.name
#   region = var.region
# }


# kafka resources may get stuck while destroying
#
# module "kafka" {
#   source     = "./modules/kafka"
#   depends_on = [module.k8s]
#   kafka_ns = module.k8s.kafka_ns
#   kubeconfig = module.eks.kubeconfig
#   public_subnet_cidrs = module.network.public_subnet_cidrs
#   private_subnet_cidrs = module.network.private_subnet_cidrs
# }

# kubernetes_manifest issues
#
# module "prometheus" {
#   source                     = "./modules/addons/prometheus"
#   pg_password                = var.pg_password
#   pg_username                = var.pg_password
#   certificate_authority_data = base64decode(module.eks.cluster.certificate_authority.0.data)
#   eks_endpoint               = module.eks.cluster.endpoint
#   eks_name                   = module.eks.cluster.name
#   # depends_on = [ module.eks, module.istio]
# }