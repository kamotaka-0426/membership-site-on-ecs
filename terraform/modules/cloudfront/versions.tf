# /terraform/modules/cloudfront/versions.tf
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # Alias provider required because ACM certificates for CloudFront must be in us-east-1
      configuration_aliases = [aws.us_east_1]
    }
  }
}
