# /terraform/modules/nw/sg.tf
# AWS-managed prefix list of IP ranges CloudFront uses for origin requests
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

# ---------------------------------------------
# Security Group — ECS Tasks
# Allow inbound port 8000 from CloudFront origin-facing IPs only
# ---------------------------------------------
resource "aws_security_group" "ecs_tasks" {
  name        = "membership-blog-ecs-tasks-sg"
  description = "Allow inbound port 8000 from CloudFront origin-facing IPs only"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
    description     = "CloudFront origin-facing IPs"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "membership-blog-ecs-tasks-sg" }
}

# ---------------------------------------------
# Security Group — RDS
# Allow PostgreSQL inbound from within the VPC only
# ---------------------------------------------
resource "aws_security_group" "db" {
  name        = "membership-blog-db-sg"
  description = "Allow PostgreSQL inbound from within VPC"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "membership-blog-db-sg" }
}
