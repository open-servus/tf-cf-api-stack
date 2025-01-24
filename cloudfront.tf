resource "aws_cloudfront_vpc_origin" "nlb" {
  vpc_origin_endpoint_config {
    name                   = "${var.application}-${var.environment}"
    arn                    = aws_lb.nlb.arn
    http_port              = 80
    https_port             = 443
    origin_protocol_policy = "https-only"

    origin_ssl_protocols {
      items    = ["TLSv1.2"]
      quantity = 1
    }
  }
  timeouts {
    create = "30m"
  }
}

locals {
  private_api_origin_id = "myprivateapi"
}

resource "aws_cloudfront_distribution" "distribution" {
  origin {
    domain_name              = aws_vpc_endpoint.api.dns_entry[0].dns_name
    origin_id                = local.private_api_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.application}-${var.environment}"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.private_api_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }

  tags = {
    Environment = var.environment
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}