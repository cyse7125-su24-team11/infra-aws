terraform {
  # required_version = "~> 1.9.0"
  # cloud {
  #   organization = "csye7125"

  #   workspaces {
  #     name = "kafka"
  #   }
  # }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kafka = {
      source  = "mongey/kafka"
      version = "0.7.1" # Use the desired version
    }
  }
}


# Configure the AWS Provider
provider "aws" {
  region = var.region
}