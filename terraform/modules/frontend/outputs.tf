# /terraform/modules/frontend/outputs.tf
output "distribution_id" {
  value       = aws_cloudfront_distribution.frontend.id
  description = "CloudFront distribution ID (used for cache invalidation)"
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.frontend.id
  description = "S3 bucket name for frontend assets"
}
