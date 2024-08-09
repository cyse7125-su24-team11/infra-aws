terraform {
  required_version = "~>1.8.3"
  backend "s3" {
    bucket = "terraform-csye7125"
    key    = "eks.tfstate"
    region = "us-east-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.18.1"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.0" # Adjust to your needs
    }
  }

}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}

provider "local" {}
