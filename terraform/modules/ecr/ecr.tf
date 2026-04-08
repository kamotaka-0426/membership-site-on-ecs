# /terraform/modules/ecr/ecr.tf
resource "aws_ecr_repository" "app" {
  name                 = "membership-blog-api"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

# Lifecycle policy to auto-delete old images and reduce storage costs
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        # Delete untagged images after 1 day
        rulePriority = 1
        description  = "Remove untagged images after 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = { type = "expire" }
      },
      {
        # Keep only the 10 most recent images regardless of tag (SHA + latest = 1 deploy, so ~5 generations)
        rulePriority = 2
        description  = "Keep only the 10 most recent images regardless of tag"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = { type = "expire" }
      }
    ]
  })
}
