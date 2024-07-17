terraform {
  # required_version = "~>1.5.3"
  # backend "s3" {
  #   bucket = "terraform-csye7125"
  #   key    = "eks.tfstate"
  #   region = "us-east-1"
  # }
  # cloud {
  #   organization = "csye7125"
  #   workspaces {
  #     name = "root"
  #   }
  # }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

}

# Configure the AWS Provider
provider "aws" {
  region = var.region
  # shared_config_files      = ["~/.aws/config"]
  # shared_credentials_files = ["~/.aws/credentials"]
  # profile                  = "dev"
}

provider "kubernetes" {
  host                   = module.eks.cluster.endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster.certificate_authority.0.data)
  token                  = module.k8s.cluster_auth_token
  # exec {
  #   api_version = "client.authentication.k8s.io/v1beta1"
  #   args        = ["eks", "get-token", "--cluster-name", module.eks.cluster.name, "--role-arn", module.iam.eks_cluster_role]
  #   command     = "aws"
  # }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster.endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster.certificate_authority.0.data)
    token                  = module.k8s.cluster_auth_token
  }
}
