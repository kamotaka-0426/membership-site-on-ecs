# Route53 Hosted Zone ID
# output "route53_zone_id" {
#   value       = data.aws_route53_zone.main.zone_id
#   description = "The ID of the Route53 Hosted Zone"
# }

output "domain_name" {
  value = "kamotaka.net"
}

# S3 bucket name for remote state storage
output "terraform_state_bucket_name" {
  value       = aws_s3_bucket.terraform_state.bucket
  description = "The name of the S3 bucket for remote state"
}

# DynamoDB table name for state locking
output "terraform_locks_table_name" {
  value       = aws_dynamodb_table.terraform_locks.name
  description = "The name of the DynamoDB table for state locking"
}