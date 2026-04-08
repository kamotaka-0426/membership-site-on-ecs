# /terraform/modules/lambda/outputs.tf
output "function_name" {
  value       = aws_lambda_function.update_origin.function_name
  description = "Lambda function name"
}
