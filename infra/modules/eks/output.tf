output "eks_cluster_name" {
  value = aws_eks_cluster.eks.name
}

output "oidc_cert" {
  value = data.tls_certificate.oidc_cert.certificates[0].sha1_fingerprint
}

output "oidc_provider_url" {
  value = data.tls_certificate.oidc_cert.url
}

output "ebs_csi" {
  value = aws_eks_addon.ebs_csi
}

output "kubeconfig" {
  value = null_resource.update_kubeconfig
}

output "cluster" {
  value = aws_eks_cluster.eks
}
