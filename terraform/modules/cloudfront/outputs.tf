# /terraform/modules/cloudfront/outputs.tf
output "distribution_id" {
  value = aws_cloudfront_distribution.main.id
}

output "acm_validation_cname_name" {
  value = [for record in aws_route53_record.acm_validation : record.name][0]
}

output "acm_validation_cname_value" {
  # tolist() converts the Set to a List so we can index with [0]
  value = [for record in aws_route53_record.acm_validation : tolist(record.records)[0]][0]
}

output "distribution_domain_name" {
  value = aws_cloudfront_distribution.main.domain_name
}
