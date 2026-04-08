# # /terraform/envs/dev/variables.tf

variable "github_repo" {
  type        = string
  description = "GitHub repository path (e.g. user/repo)"
}

variable "domain_name" {
  type        = string
  description = "Root domain name (e.g. example.com)"
}