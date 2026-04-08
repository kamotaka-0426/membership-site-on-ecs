# /terraform/modules/lambda/function.tf
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/../../../lambda/update_cloudfront_origin/index.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "update_origin" {
  filename         = data.archive_file.lambda.output_path
  function_name    = "membership-blog-update-cloudfront-origin"
  role             = aws_iam_role.lambda.arn
  handler          = "index.handler"
  runtime          = "python3.12"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      ROUTE53_ZONE_ID  = var.route53_zone_id
      ORIGIN_HOSTNAME  = var.origin_hostname
      ROUTE53_ROLE_ARN = aws_iam_role.route53_update.arn
    }
  }
}