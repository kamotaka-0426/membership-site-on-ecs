# /terraform/modules/ecs/iam.tf
# ---------------------------------------------
# IAM — Task Execution Role
# Required for ECR image pulls, CloudWatch Logs writes, and Secrets Manager reads
# ---------------------------------------------
resource "aws_iam_role" "task_execution" {
  name = "membership-blog-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "task_execution_policy" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Grant permission to read DB password and JWT secret from Secrets Manager
resource "aws_iam_role_policy" "task_execution_secrets" {
  name = "membership-blog-task-execution-secrets"
  role = aws_iam_role.task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["secretsmanager:GetSecretValue"]
      Resource = [
        var.db_secret_arn,
        aws_secretsmanager_secret.jwt_secret.arn,
      ]
    }]
  })
}
