
output "eks_cluster" {
  value = aws_eks_cluster.eks
}
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

# output "eks_cluster" {
#   # value = aws_eks_cluster.eks
#   value = module.eks
# }
# output "eks_cluster_name" {
#   # value = aws_eks_cluster.eks
#   value = module.eks.cluster_name
# }

# output "oidc_cert" {
#   # value = data.tls_certificate.oidc_cert
#   value = module.eks.cluster_tls_certificate_sha1_fingerprint
# }
# output "oidc_provider_url" {
#   # value = data.tls_certificate.oidc_cert
#   value = module.eks.cluster_oidc_issuer_url
# }

# output "ebs_csi" {
#   # value = aws_eks_addon.ebs_csi
#   value = module.eks.cluster_addons.aws-ebs-csi-driver
# }


# I dont know what these are for yet
# output "endpoint" {
#   value = module.eks.endpoint
# }

# output "kubeconfig-certificate-authority-data" {
#   value = module.eks.certificate_authority
# }

