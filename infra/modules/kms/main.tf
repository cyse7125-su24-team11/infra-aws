# Create KMS key for encrypting Kubernetes secrets
data "aws_kms_key" "eks_secrets" {
  key_id = "arn:aws:kms:us-east-1:533267343403:key/b0ca221d-7cf3-4cde-8a49-145a70de913b"
}

data "aws_kms_key" "ebs_kms_key_arn" {
  key_id = "arn:aws:kms:us-east-1:533267343403:key/a1ee6798-157e-47c0-aec3-53566eb9cc7a"
}
# resource "aws_kms_alias" "eks_secrets_alias" {
#   name          = "alias/eks-secrets"
#   target_key_id = aws_kms_key.eks_secrets.key_id
# }