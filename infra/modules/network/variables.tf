
variable "region" {
  type    = string
  default = "us-east-1"
}
variable "vpc_name" {
  type    = string
  default = "cve-vpc"
}
variable "aws_availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1d"]
}
variable "eks_vpc_cidr_block" {
  type    = string
  default = "10.2.0.0/16"
}
variable "internet_gw" {
  type    = string
  default = "internet_gateway"
}
variable "eks_private_subnets" {
  type    = list(string)
  default = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
}
variable "eks_public_subnets" {
  type    = list(string)
  default = ["10.2.4.0/24", "10.2.5.0/24", "10.2.6.0/24"]
}
variable "route_table_name" {
  type    = string
  default = "public_route_table"
}
variable "sg_name" {
  type    = string
  default = "eks_sg"
}
variable "tcp_protocol" {
  type    = string
  default = "tcp"
}
variable "https_default_port" {
  type    = number
  default = 443
}
variable "app_port" {
  type    = number
  default = 8080
}
variable "app_default_port" {
  type    = number
  default = 80
}
variable "ssh_default_port" {
  type    = number
  default = 22
}
variable "internet_gateway" {
  type    = string
  default = "0.0.0.0/0"
}