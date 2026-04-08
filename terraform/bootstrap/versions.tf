# /terraform/bootstrap/versions.tf

# ---------------------------------------------
# Terraform configuration
# ---------------------------------------------
terraform {
  required_version = ">=0.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

# ---------------------------------------------
# Provider
# ---------------------------------------------
provider "aws" {
  region = "ap-northeast-1"
  profile = "dev-infra-01"
}

# ACM certificate for CloudFront must be in us-east-1 (kept here for reference)
# provider "aws" {
#   alias  = "us_east_1"
#   region = "us-east-1"
#   profile = "dev-infra-01"
# }