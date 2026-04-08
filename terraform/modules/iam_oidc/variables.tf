# /terraform/modules/iam_oidc/variables.tf
variable "github_repo" {
  type        = string
  description = "GitHub repository name (e.g. 'user/repo')"
}
