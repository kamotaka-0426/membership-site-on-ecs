# /terraform/modules/rds/variables.tf
variable "vpc_id" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "db_sg_id" {
  type        = string
  description = "Security Group ID for RDS (from sg module)"
}
