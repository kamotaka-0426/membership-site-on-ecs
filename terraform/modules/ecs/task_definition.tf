# /terraform/modules/ecs/task_definition.tf
resource "aws_ecs_task_definition" "app" {
  family                   = "membership-blog-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"  # 0.25 vCPU
  memory                   = "512"  # 512 MB (free tier)
  execution_role_arn       = aws_iam_role.task_execution.arn

  container_definitions = jsonencode([{
    name  = "api"
    image = var.ecr_image_uri
    portMappings = [{
      containerPort = 8000
      protocol      = "tcp"
    }]
    # distroless has no shell, so invoke Python directly via CMD form
    healthCheck = {
      command     = ["CMD", "/usr/bin/python3", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"]
      interval    = 30  # check every 30 seconds
      timeout     = 5   # fail if no response within 5 seconds
      retries     = 3   # mark unhealthy after 3 consecutive failures
      startPeriod = 60  # ignore failures for 60s after start (DB connection warmup)
    }
    environment = [
      { name = "DB_USER",              value = "postgres" },
      { name = "DB_NAME",              value = "membership_db" },
      { name = "DB_HOST",              value = var.db_host },
      { name = "ORIGIN_VERIFY_SECRET", value = var.origin_verify_secret },
      { name = "ADMIN_EMAIL",          value = var.admin_email },
    ]
    # Inject secrets from Secrets Manager — never stored in plaintext in the task definition
    secrets = [
      {
        name      = "DB_PASSWORD"
        valueFrom = var.db_secret_arn
      },
      {
        name      = "JWT_SECRET_KEY"
        valueFrom = aws_secretsmanager_secret.jwt_secret.arn
      },
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.app.name
        "awslogs-region"        = "ap-northeast-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}
