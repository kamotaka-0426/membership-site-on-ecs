# Route53 hosted zone — provisioned as part of the bootstrap foundation
resource "aws_route53_zone" "main" {
  name = "kamotaka.net"
}