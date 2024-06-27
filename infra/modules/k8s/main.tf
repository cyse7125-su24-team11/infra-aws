data "aws_eks_cluster_auth" "cluster_auth" {
  name = var.eks_name
}

provider "kubernetes" {
  host                   = var.eks_endpoint
  cluster_ca_certificate = var.certificate_authority_data
  token                  = data.aws_eks_cluster_auth.cluster_auth.token
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.eks_name, "--role-arn", var.eks_cluster_role]
    command     = "aws"
  }
}

resource "null_resource" "kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks --region ${var.region} update-kubeconfig --name ${var.eks_name}"
  }
  depends_on = [var.eks_name]
}

resource "kubernetes_config_map_v1_data" "aws_auth_configmap" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
  force = true
  data = {
    mapRoles = <<YAML
    - rolearn: ${var.node_group_iam_role.arn}
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
  depends_on = [ var.node_group, null_resource.kubeconfig ]
}

resource "kubernetes_namespace" "cve_processor_job_ns" {
  metadata {
    name = "cve-processor-job-ns"
  }
  depends_on = [ null_resource.kubeconfig ]
}


