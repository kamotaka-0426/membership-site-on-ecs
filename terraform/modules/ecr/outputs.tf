# /terraform/modules/ecr/outputs.tf
output "repository_url" {
  value = aws_ecr_repository.app.repository_url
}
