# /terraform/modules/frontend/variables.tf
variable "domain_name" {
  type        = string
  description = "Frontend domain (e.g. kamotaka.net)"
}

variable "route53_zone_id" {
  type        = string
  description = "Route53 hosted zone ID"
}
