#
## Add EKS Cluster, this will get created after all dependant modules - KMS, Network, 
## but will work in parallel with Node Group and IAM. This is because CoreDNS Add On requires nodes to be active 
## before it's installation can come to completion. For IAM, it needs to send OIDC url
##

data "aws_eks_cluster_auth" "cluster_auth" {
  name = var.eks_name
}

provider "kubernetes" {
  host                   = aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster_auth.token
}

resource "kubernetes_config_map_v1_data" "aws_auth_configmap" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
  force=true
  data = {
    mapRoles = <<YAML
    - rolearn: ${var.node_group_role.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
    - rolearn: ${var.vpc_cni_role.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
    - rolearn: ${var.ebs_csi_role.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
    - rolearn: ${var.eks_cluster_role}
      username: kubectl-access-user
      groups:
        - system:masters
    YAML
  }
}
# - rolearn: ${<worker node ARN>}
#   username: system:node:{{EC2PrivateDNSName}}
#   groups:
#     - system:bootstrappers
#     - system:nodes

resource "aws_eks_cluster" "eks" {
  name     = var.eks_name
  role_arn = var.eks_cluster_role
  version  = var.k8s_version

  access_config {
    authentication_mode                         = var.eks_authentication_mode
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    subnet_ids = [
      var.public_subnets[0].id,
      var.public_subnets[1].id,
      var.public_subnets[2].id,
      var.private_subnets[0].id,
      var.private_subnets[1].id,
      var.private_subnets[2].id
    ]

    security_group_ids = [var.eks_sg.id]
  }

  kubernetes_network_config {
    ip_family = var.kubernetes_network_config
  }

  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = var.eks_secrets_arn
    }
  }
  enabled_cluster_log_types = var.enabled_cluster_log_types

  depends_on = [
    var.public_subnets,
    var.private_subnets,
    aws_cloudwatch_log_group.cluster_logging,
  ]
}

# Enable Cloudwatch logging 
resource "aws_cloudwatch_log_group" "cluster_logging" {
  name              = "/aws/eks/${var.eks_name}/cluster"
  retention_in_days = var.retention_in_days
}


## EKS Add ons
##
##
resource "aws_eks_addon" "pod_identity" {
  cluster_name                = aws_eks_cluster.eks.name
  addon_name                  = var.pod_identity_addon_name
  addon_version               = var.pod_identity_addon_version
  resolve_conflicts_on_update = var.resolve_conflicts_on_update
  service_account_role_arn    = var.eks_pod_identity_role.arn

  configuration_values = jsonencode({
    "agent" : {
      "additionalArgs" : {
        "-b" : "169.254.170.23"
      }
    }
  })

  depends_on = [
    aws_eks_cluster.eks,
  ]
}

resource "aws_eks_addon" "core_dns" {
  cluster_name                = aws_eks_cluster.eks.name
  addon_name                  = var.core_dns_addon_name
  addon_version               = var.core_dns_addon_version
  resolve_conflicts_on_update = var.resolve_conflicts_on_update

  configuration_values = jsonencode({
    replicaCount = 0
  })
  depends_on = [
    aws_eks_cluster.eks,
  ]
}

resource "aws_eks_addon" "kube-proxy" {
  cluster_name                = aws_eks_cluster.eks.name
  addon_name                  = var.kube-proxy_addon_name
  addon_version               = var.kube-proxy_addon_version
  resolve_conflicts_on_update = var.resolve_conflicts_on_update

  depends_on = [
    aws_eks_cluster.eks,
  ]
}

resource "aws_eks_addon" "vpc-cni" {
  cluster_name                = aws_eks_cluster.eks.name
  addon_name                  = var.vpc_cni_addon_name
  addon_version               = var.vpc_cni_addon_version
  resolve_conflicts_on_update = var.resolve_conflicts_on_update
  service_account_role_arn    = var.vpc_cni_role.arn
  configuration_values        = null
  depends_on = [
    aws_eks_cluster.eks,
  ]
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name  = aws_eks_cluster.eks.name
  addon_name    = var.ebs_csi_addon_name
  addon_version = var.ebs_csi_addon_version

  service_account_role_arn = var.ebs_csi_role.arn
  # timeouts {
  #   create = "13m"
  # }
  preserve                    = false
  resolve_conflicts_on_update = var.resolve_conflicts_on_update
  configuration_values        = null
  depends_on = [
    aws_eks_cluster.eks,
  ]
}


data "tls_certificate" "oidc_cert" {
  url = aws_eks_cluster.eks.identity[0].oidc[0].issuer
  depends_on = [
    aws_eks_cluster.eks,
  ]
}