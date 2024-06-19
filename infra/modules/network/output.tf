output "eks_vpc" {
  value = aws_vpc.eks_vpc
}

output "public_subnets" {
  value = aws_subnet.public_subnets[*]
}

output "private_subnets" {
  value = aws_subnet.private_subnets[*]
}

output "internet_gateway" {
  value = aws_internet_gateway.gw
}

output "eks_sg" {
  value = aws_security_group.eks_sg
}