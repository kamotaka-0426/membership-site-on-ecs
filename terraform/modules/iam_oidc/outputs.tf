# /terraform/modules/iam_oidc/outputs.tf
output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}
