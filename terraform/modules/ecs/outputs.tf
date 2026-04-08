# /terraform/modules/ecs/outputs.tf
output "cluster_arn" {
  value       = aws_ecs_cluster.main.arn
  description = "ECS cluster ARN (used by Lambda EventBridge rule)"
}

output "ecs_task_execution_role_arn" {
  value       = aws_iam_role.task_execution.arn
  description = "ARN of ECS task execution role"
}

output "alarm_sns_topic_arn" {
  value       = aws_sns_topic.ecs_alarms.arn
  description = "SNS topic ARN for ECS alarms — subscribe your email to receive notifications"
}
