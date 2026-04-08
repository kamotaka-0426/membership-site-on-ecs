# /terraform/modules/ecs/variables.tf
variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs for ECS tasks"
}

variable "ecs_tasks_sg_id" {
  type        = string
  description = "Security Group ID for ECS tasks (from sg module)"
}

variable "ecr_image_uri" {
  type        = string
  description = "ECR image URI (e.g. 123456789.dkr.ecr.ap-northeast-1.amazonaws.com/repo:latest)"
}

variable "db_host" {
  type        = string
  description = "RDS instance hostname"
}

variable "db_secret_arn" {
  type        = string
  description = "Secrets Manager secret ARN for DB password"
}

variable "origin_verify_secret" {
  type        = string
  description = "Secret value for X-Origin-Verify header (injected as env var for FastAPI validation)"
  sensitive   = true
}

variable "admin_email" {
  type        = string
  description = "Email address granted admin privileges (post deletion for any post)"
  default     = ""
}
