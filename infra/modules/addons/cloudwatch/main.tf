resource "aws_eks_addon" "cloudwatch-observability" {
  cluster_name  = var.eks_cluster_name
  addon_name    = "amazon-cloudwatch-observability"
  addon_version = "v1.8.0-eksbuild.1"

  service_account_role_arn = var.cloudwatch_role_arn

  depends_on = [
    aws_eks_cluster.eks,
  ]
}


resource "kubernetes_service_account" "cloudwatch-sa" {
  metadata {
    name      = "cloudwatch-sa"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = var.cloudwatch_role_arn
    }
  }
    depends_on = [
    aws_eks_cluster.eks,
  ]
}
