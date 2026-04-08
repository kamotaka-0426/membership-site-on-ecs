# /terraform/modules/lambda/iam.tf
resource "aws_iam_role" "lambda" {
  name = "membership-blog-update-origin-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda" {
  name = "membership-blog-update-origin-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Write Lambda logs to CloudWatch Logs
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        # Read ECS task details
        Effect   = "Allow"
        Action   = ["ecs:DescribeTasks", "ecs:ListTasks"]
        Resource = "*"
      },
      {
        # Look up public IP from ENI
        Effect   = "Allow"
        Action   = ["ec2:DescribeNetworkInterfaces"]
        Resource = "*"
      },
      {
        # Assume cross-account role (Route53 hosted zone lives in a separate account)
        Effect   = "Allow"
        Action   = ["sts:AssumeRole"]
        Resource = "arn:aws:iam::071308038382:role/membership-blog-route53-update-role"
      },
    ]
  })
}

resource "aws_iam_role" "route53_update" {
  name = "membership-blog-route53-update-role"

  # Trust policy: allow the Lambda execution role to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.lambda.arn
        }
      }
    ]
  })
}

# Grant Route 53 record update permission
resource "aws_iam_role_policy" "route53_update_policy" {
  name = "route53-update-policy"
  role = aws_iam_role.route53_update.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "route53:ChangeResourceRecordSets"
        Effect   = "Allow"
        Resource = "arn:aws:route53:::hostedzone/${var.route53_zone_id}"
      }
    ]
  })
}