# /terraform/envs/dev/main.tf

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
  backend "s3" {
    bucket         = "membership-blog-on-ecs-tfstate-20260405"
    key            = "dev/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "terraform-state-locking"
    encrypt        = true
  }
}

# ---------------------------------------------
# Provider
# ---------------------------------------------
provider "aws" {
  region = "ap-northeast-1"
  profile = "dev-infra-01"
}

# ACM certificate for CloudFront must be in us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  profile = "dev-infra-01"
}

# ---------------------------------------------
# Secret for CloudFront custom header
# CloudFront attaches this to every origin request; FastAPI validates it
# ---------------------------------------------
resource "random_uuid" "origin_verify_secret" {}

# ---------------------------------------------
# Module calls
# ---------------------------------------------
# 1. Network module (VPC + Security Groups)
module "nw" {
  source = "../../modules/nw"
}

# 2. ECR module
module "ecr" {
  source = "../../modules/ecr"
}

# 3. OIDC module (for GitHub Actions)
module "iam_oidc" {
  source      = "../../modules/iam_oidc"
  github_repo = var.github_repo
}

# 4. RDS module
module "rds" {
  source             = "../../modules/rds"
  vpc_id             = module.nw.vpc_id
  private_subnet_ids = module.nw.private_subnet_ids
  db_sg_id           = module.nw.db_sg_id
}

# 5. ECS module (no ALB; CloudFront custom header validation enabled)
module "ecs" {
  source               = "../../modules/ecs"
  vpc_id               = module.nw.vpc_id
  public_subnet_ids    = module.nw.public_subnet_ids
  ecs_tasks_sg_id      = module.nw.ecs_tasks_sg_id
  ecr_image_uri        = "${module.ecr.repository_url}:latest"
  db_host              = module.rds.db_instance_endpoint
  db_secret_arn        = module.rds.db_secret_arn
  origin_verify_secret = random_uuid.origin_verify_secret.result
}

# 7. CloudFront module
# Initial origin is a placeholder (1.1.1.1).
# Lambda updates it to the real ECS task IP once the task is running.
module "cloudfront" {
  source               = "../../modules/cloudfront"
  route53_zone_id = data.aws_route53_zone.main.zone_id
  origin_verify_secret = random_uuid.origin_verify_secret.result
  domain_name          = "api.${var.domain_name}"

  origin_domain_name   = "ecs-origin.${var.domain_name}"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
}

# 8. Lambda module
module "lambda" {
  source           = "../../modules/lambda"
  # Route53 hosted zone is in the dev-infra-01 account (071308038382)
  route53_zone_id  = data.aws_route53_zone.main.zone_id
  origin_hostname  = "ecs-origin.${var.domain_name}"
  ecs_cluster_arn  = module.ecs.cluster_arn
}

# 9. Frontend module (private S3 + CloudFront OAC)
data "aws_route53_zone" "main" {
  name         = "${var.domain_name}."
  private_zone = false
}
module "frontend" {
  source          = "../../modules/frontend"
  domain_name     = var.domain_name
  route53_zone_id = data.aws_route53_zone.main.zone_id

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
}

# ---------------------------------------------
# Outputs
# ---------------------------------------------
output "github_actions_role_arn" {
  value       = module.iam_oidc.github_actions_role_arn
  description = "ARN of IAM role for GitHub Actions"
}

output "vpc_id" {
  value = module.nw.vpc_id
}

output "cloudfront_api_url" {
  value       = "https://api.${var.domain_name}"
  description = "API endpoint — set this as API_URL in frontend/src/App.jsx"
}

output "acm_validation_cname_name" {
  value       = module.cloudfront.acm_validation_cname_name
  description = "CNAME hostname for ACM certificate DNS validation"
}

output "acm_validation_cname_value" {
  value       = module.cloudfront.acm_validation_cname_value
  description = "CNAME value for ACM certificate DNS validation"
}

output "cloudfront_cname_value" {
  value       = module.cloudfront.distribution_domain_name
  description = "CNAME value to set for api.kamotaka.net in your DNS registrar"
}

output "frontend_s3_bucket_name" {
  value       = module.frontend.s3_bucket_name
  description = "Frontend S3 bucket name — set as GitHub Secret: S3_BUCKET_NAME"
}

output "frontend_cloudfront_distribution_id" {
  value       = module.frontend.distribution_id
  description = "Frontend CloudFront distribution ID — set as GitHub Secret: CLOUDFRONT_DISTRIBUTION_ID"
}

output "Checking_RDS_PASS_COMMAND" {
  value = "terraform output -raw temporary_db_password"
}

output "temporary_db_password" {
  value     = module.rds.db_password_raw
  sensitive = true
}

output "alarm_sns_topic_arn" {
  value       = module.ecs.alarm_sns_topic_arn
  description = "SNS topic for alarm notifications. Subscribe an email address with:\n  aws sns subscribe --topic-arn <arn> --protocol email --notification-endpoint you@example.com"
}

# ---------------------------------------------
# Data sources
# ---------------------------------------------
data "terraform_remote_state" "bootstrap" {
  backend = "local"
  config = {
    path = "../../bootstrap/terraform.tfstate"
  }
}
