output "eks_secrets_arn" {
  value = data.aws_kms_key.eks_secrets.arn
}
output "ebs_kms_key_arn" {
  value = data.aws_kms_key.ebs_kms_key_arn.arn
}
