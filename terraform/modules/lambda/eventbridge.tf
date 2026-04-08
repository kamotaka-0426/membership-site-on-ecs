# /terraform/modules/lambda/eventbridge.tf
# Trigger Lambda when an ECS task transitions to RUNNING
resource "aws_cloudwatch_event_rule" "ecs_task_running" {
  name        = "membership-blog-ecs-task-running"
  description = "Invoke Lambda to update the CloudFront origin when an ECS task reaches RUNNING state"

  event_pattern = jsonencode({
    source      = ["aws.ecs"]
    detail-type = ["ECS Task State Change"]
    detail = {
      clusterArn = [var.ecs_cluster_arn]
      lastStatus = ["RUNNING"]
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.ecs_task_running.name
  target_id = "UpdateCloudfrontOrigin"
  arn       = aws_lambda_function.update_origin.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_origin.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ecs_task_running.arn
}
