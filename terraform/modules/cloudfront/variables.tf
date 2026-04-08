# /terraform/modules/cloudfront/variables.tf
variable "origin_verify_secret" {
  type        = string
  description = "Secret value for X-Origin-Verify custom header"
  sensitive   = true
}

variable "domain_name" {
  type        = string
  description = "Custom domain for CloudFront (e.g. api.kamotaka.net)"
}

variable "origin_domain_name" {
  type        = string
  description = "FQDN for CloudFront origin (e.g. ecs-origin.kamotaka.net)"
}

variable "route53_zone_id" {
  type        = string
  description = "Route53 hosted zone ID used for ACM DNS validation"
}
