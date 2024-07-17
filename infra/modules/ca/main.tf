resource "helm_release" "ca" {
  name       = "helm-eks-autoscaler"
  repository = "https://github.com/cyse7125-su24-team11/helm-eks-autoscaler/main/"
  chart      = "/"
  version    = "0.1.0"
  repository_username = "anibahs"
  repository_password = "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"

  set {
    name  = "caRoleArn"
    value = var.caRoleArn
  }

  set_sensitive {
    name  = "dockerconfigjson"
    value = file("/Users/shabinasingh/.docker/config.json")
  }
}