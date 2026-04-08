# /terraform/modules/ecs/cloudwatch.tf

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/membership-blog-api"
  retention_in_days = 7
}

# ---------------------------------------------
# SNS topic for alarm notifications.
# After applying, subscribe an email address via CLI:
#   aws sns subscribe --topic-arn <arn> --protocol email --notification-endpoint you@example.com
# ---------------------------------------------
resource "aws_sns_topic" "ecs_alarms" {
  name = "membership-blog-ecs-alarms"
}

# ---------------------------------------------
# CPU utilization alarm — alert when 5-minute average exceeds 80%
# ---------------------------------------------
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "membership-blog-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "ECS CPU utilization exceeded 80% for 10 minutes"
  alarm_actions       = [aws_sns_topic.ecs_alarms.arn]
  ok_actions          = [aws_sns_topic.ecs_alarms.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.app.name
  }
}

# ---------------------------------------------
# Memory utilization alarm — alert when 5-minute average exceeds 80%
# ---------------------------------------------
resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  alarm_name          = "membership-blog-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "ECS memory utilization exceeded 80% for 10 minutes"
  alarm_actions       = [aws_sns_topic.ecs_alarms.arn]
  ok_actions          = [aws_sns_topic.ecs_alarms.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.app.name
  }
}

# ---------------------------------------------
# Running task count alarm — immediate alert when count drops below 1 (crash detection)
# ---------------------------------------------
resource "aws_cloudwatch_metric_alarm" "ecs_task_count_low" {
  alarm_name          = "membership-blog-ecs-task-count-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "RunningTaskCount"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "Running ECS task count dropped below 1"
  alarm_actions       = [aws_sns_topic.ecs_alarms.arn]
  ok_actions          = [aws_sns_topic.ecs_alarms.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.app.name
  }
}
