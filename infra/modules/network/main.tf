######################################################################################
## --------------------------------------VPC----------------------------------------##
######################################################################################

resource "aws_vpc" "eks_vpc" {
  cidr_block = var.eks_vpc_cidr_block
  tags = {
    Name = var.vpc_name
  }
  enable_dns_support = true
  enable_dns_hostnames = true
}


######################################################################################
## ---------------------------------Public Subnet------------------------------------##
######################################################################################

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.eks_vpc.id
  tags = {
    Name = "${var.vpc_name}-internet-gw"
  }
  depends_on = [aws_vpc.eks_vpc]
}


resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = var.route_table_name
  }
  depends_on = [aws_internet_gateway.gw ]
}

resource "aws_subnet" "public_subnets" {
  vpc_id                  = aws_vpc.eks_vpc.id
  count                   = length(var.eks_public_subnets)
  cidr_block              = var.eks_public_subnets[count.index]
  availability_zone       = var.aws_availability_zones[count.index % length(var.aws_availability_zones)]
  map_public_ip_on_launch = true

  tags = {
    "Name"                                  = "${var.vpc_name}-public-subnet-${count.index}"
    "kubernetes.io/cluster/${var.vpc_name}" = "shared"
  }
  depends_on = [aws_vpc.eks_vpc]
}

resource "aws_route_table_association" "public_subnets_route" {
  count          = length(var.eks_public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_route_table.id
  depends_on     = [aws_subnet.public_subnets, aws_route_table.public_route_table]
}




######################################################################################
## --------------------------------Private Subnet-----------------------------------##
######################################################################################

resource "aws_eip" "elastic_ip" {
  count  = length(var.eks_private_subnets)
  domain = "vpc"

  tags = {
    "Name" = "${var.vpc_name}-eip-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  count         = length(var.eks_public_subnets)
  allocation_id = aws_eip.elastic_ip[count.index].id
  subnet_id     = aws_subnet.public_subnets[count.index].id

  tags = {
    "Name" = "${var.vpc_name}-nat-gw-${count.index}"
  }
  depends_on = [aws_subnet.public_subnets, aws_internet_gateway.gw]
}

resource "aws_subnet" "private_subnets" {
  vpc_id                  = aws_vpc.eks_vpc.id
  count                   = length(var.eks_private_subnets)
  cidr_block              = var.eks_private_subnets[count.index]
  availability_zone       = var.aws_availability_zones[count.index % length(var.aws_availability_zones)]
  map_public_ip_on_launch = false

  tags = {
    "Name"                                  = "${var.vpc_name}-private-subnet-${count.index}"
    "kubernetes.io/cluster/${var.vpc_name}" = "shared"
  }
  depends_on = [aws_vpc.eks_vpc]
}

# Private route table
resource "aws_route_table" "private_route_table" {
  count  = length(var.eks_private_subnets)
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw[count.index].id
  }

  tags = {
    Name = "${var.vpc_name}-private-route-table-${count.index}"
  }
}

resource "aws_route_table_association" "private_subnets_rta" {
  count          = length(aws_subnet.private_subnets)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_route_table[count.index].id
  depends_on     = [aws_subnet.private_subnets, aws_route_table.private_route_table]
}






######################################################################################
## --------------------------------Security Group-----------------------------------##
######################################################################################


resource "aws_security_group" "eks_sg" {
  name   = var.sg_name
  vpc_id = aws_vpc.eks_vpc.id

  ingress {
    protocol    = "-1"
    # cidr_blocks = [var.internet_gateway]
    from_port   = 0
    to_port     = 0
    self = true
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = var.sg_name
  }
  depends_on = [aws_vpc.eks_vpc]

}

######################################################################################
## ---------------------------------  Endpoint  ------------------------------------##
######################################################################################
# data "aws_caller_identity" "current" {}

# resource "aws_vpc_endpoint_service" "ec2_connect" {
#   acceptance_required        = false
#   allowed_principals         = [data.aws_caller_identity.current.arn]
# }

# resource "aws_vpc_endpoint" "eks_nodes" {
#   vpc_id            = aws_vpc_endpoint_service.ec2_connect.service_name
#   service_name      = "com.amazonaws.${var.region}.ec2"
#   vpc_endpoint_type = aws_vpc_endpoint_service.ec2_connect.service_type

#   security_group_ids = [
#     aws_security_group.eks_sg.id,
#   ]
#   subnet_ids = [
#     aws_subnet.private_subnets[0].id,
#     aws_subnet.private_subnets[1].id,
#     aws_subnet.private_subnets[2].id
#   ]
#   private_dns_enabled = true
# }