# /terraform/modules/ecs/service.tf
# No ALB; tasks are assigned public IPs to reach ECR without a NAT gateway.
# CloudFront origin IP is updated dynamically by Lambda.
#
# NOTE: desired_count=2, but without an ALB only the task whose IP was most
# recently written to the Route53 A record will receive traffic.
# The second task exists solely to reduce downtime during rolling deployments.
resource "aws_ecs_service" "app" {
  name            = "membership-blog-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  # Rolling deploy: keep at least 1 task running at all times (50% of 2)
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  network_configuration {
    subnets          = var.public_subnet_ids
    security_groups  = [var.ecs_tasks_sg_id]
    assign_public_ip = true
  }
}
