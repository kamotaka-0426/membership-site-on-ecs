# /terraform/modules/nw/outputs.tf
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = [aws_subnet.public_a.id, aws_subnet.public_c.id]
}

output "private_subnet_ids" {
  value = [aws_subnet.private_a.id, aws_subnet.private_c.id]
}

output "ecs_tasks_sg_id" {
  value       = aws_security_group.ecs_tasks.id
  description = "Security Group ID for ECS Tasks"
}

output "db_sg_id" {
  value       = aws_security_group.db.id
  description = "Security Group ID for RDS"
}
