# /terraform/modules/lambda/variables.tf
variable "route53_zone_id" {
  type        = string
  description = "Route53 hosted zone ID for updating the origin A record"
}

variable "origin_hostname" {
  type        = string
  description = "Hostname of the CloudFront origin A record to update (e.g. dummy-origin.kamotaka.net)"
}

variable "ecs_cluster_arn" {
  type        = string
  description = "ECS cluster ARN to watch for task state changes"
}

# variable "route53_role_arn" {
#   type        = string
#   description = "ARN of the cross-account IAM role to assume for Route53 updates (in the account that owns the hosted zone)"
# }
