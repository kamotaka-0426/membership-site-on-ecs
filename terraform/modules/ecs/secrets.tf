# /terraform/modules/ecs/secrets.tf
# Manage the JWT signing key in Secrets Manager and inject it securely into ECS tasks

resource "random_password" "jwt_secret" {
  length  = 64
  special = false # alphanumeric only — special characters can cause encoding issues in JWT secrets
}

# Random suffix to avoid recovery-wait conflicts when destroy→apply cycles reuse the same secret name
resource "random_id" "jwt_secret_suffix" {
  byte_length = 4
}

resource "aws_secretsmanager_secret" "jwt_secret" {
  name                    = "membership-blog-jwt-secret-${random_id.jwt_secret_suffix.hex}"
  description             = "JWT signing key for FastAPI"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "jwt_secret" {
  secret_id     = aws_secretsmanager_secret.jwt_secret.id
  secret_string = random_password.jwt_secret.result
}
