# /terraform/modules/rds/instance.tf
resource "aws_db_subnet_group" "main" {
  name       = "membership-blog-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = { Name = "membership-blog-db-subnet-group" }
}

resource "aws_db_instance" "main" {
  identifier             = "membership-blog-db"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro" # free tier eligible
  allocated_storage      = 20            # free tier limit: 20 GB
  db_name                = "membership_db"
  username               = "postgres"
  password               = random_password.db_password.result
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_sg_id]
  skip_final_snapshot    = true
  publicly_accessible    = false
}
