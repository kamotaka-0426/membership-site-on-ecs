# /terraform/modules/ecs/cluster.tf
resource "aws_ecs_cluster" "main" {
  name = "membership-blog-cluster"
}
