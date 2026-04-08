# /terraform/modules/cloudfront/distribution.tf
# Origin IP is dynamically updated by Lambda when ECS tasks start.
# Initial value is a placeholder (1.1.1.1).
resource "aws_cloudfront_distribution" "main" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "membership-blog-api"
  aliases         = [var.domain_name]

  origin {
    # Hostname updated by Lambda via Route53 A record when ECS tasks come up
    domain_name = var.origin_domain_name
    origin_id   = "ecs-origin"

    # Attach a custom header to all CloudFront → ECS requests.
    # FastAPI validates this header to reject direct access.
    custom_header {
      name  = "X-Origin-Verify"
      value = var.origin_verify_secret
    }

    custom_origin_config {
      http_port              = 8000 # Port FastAPI listens on
      https_port             = 443
      origin_protocol_policy = "http-only" # HTTP to ECS; CloudFront terminates HTTPS
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "ecs-origin"

    # No caching for API responses (CachingDisabled managed policy)
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"

    # Forward all headers (Authorization, Content-Type, etc.) to origin
    # (AllViewerExceptHostHeader managed policy)
    origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"

    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # ACM certificate — SNI-based, TLS 1.2 minimum
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.api.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # Wait for ACM certificate validation before creating the distribution
  depends_on = [aws_acm_certificate_validation.api]
}
