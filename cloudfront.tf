/*
  This Terraform configuration defines resources for setting up an AWS CloudFront distribution with a VPC origin.

  Resources:
  - aws_cloudfront_vpc_origin.nlb: Configures a VPC origin for CloudFront with specified endpoint configuration and timeouts.
    - vpc_origin_endpoint_config: Specifies the VPC origin endpoint configuration including name, ARN, ports, and SSL protocols.
    - timeouts: Defines the timeouts for create, update, and delete operations.

  - local.private_api_origin_id: Defines a local variable for the private API origin ID.

  - aws_cloudfront_distribution.distribution: Configures a CloudFront distribution with the specified origin, cache behavior, restrictions, tags, and viewer certificate.
    - origin: Specifies the origin configuration including domain name, origin ID, path, custom headers, and VPC origin config.
    - default_cache_behavior: Defines the default cache behavior including allowed methods, forwarded values, and TTL settings.
    - restrictions: Configures geo-restrictions for the distribution.
    - tags: Adds tags to the CloudFront distribution.
    - viewer_certificate: Specifies the viewer certificate configuration for the distribution.
*/
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
    update = "30m"
    delete = "30m"
  }
}

locals {
  private_api_origin_id = "myprivateapi"
}

resource "aws_cloudfront_distribution" "distribution" {
  origin {
    domain_name = aws_vpc_endpoint.api.dns_entry[0].dns_name
    origin_id   = local.private_api_origin_id
    origin_path = "/${var.environment}"
    custom_header {
      name  = "x-apigw-api-id"
      value = aws_api_gateway_rest_api.main.id
    }

    vpc_origin_config {
      origin_keepalive_timeout = 10
      origin_read_timeout      = 30
      vpc_origin_id            = aws_cloudfront_vpc_origin.nlb.id
    }
  }

  enabled         = true
  is_ipv6_enabled = true
  comment         = "${var.application}-${var.environment}"

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
      restriction_type = "none"
      locations        = []
    }
  }

  tags = {
    Environment = var.environment
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}