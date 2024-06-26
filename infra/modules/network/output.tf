output "eks_vpc" {
  value = aws_vpc.eks_vpc
}

output "public_subnets" {
  value = aws_subnet.public_subnets[*]
}

output "public_subnet_cidrs" {
  value = aws_subnet.public_subnets[*].cidr_block
}

output "private_subnet_cidrs" {
  value = aws_subnet.private_subnets[*].cidr_block
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