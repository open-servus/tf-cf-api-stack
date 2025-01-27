
// Terraform configuration for AWS infrastructure

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "=5.84.0"
    }
  }
}

locals {
  // Default tags for resources
  common = {
    Environment = upper("${var.environment}")
    Git         = "tf-cf-api-stack"
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = merge({
      Application = title("tao"),
    }, local.common)
  }
}

data "aws_region" "current" {}

resource "aws_vpc" "main" {
  // Main VPC configuration
  cidr_block           = "172.31.34.0/23"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name        = "${var.application}-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "gw" {
  // Internet Gateway for VPC
  vpc_id = aws_vpc.main.id
  tags = {
    Name        = "${var.application}-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_subnet" "sp1" {
  // Private subnet 1
  vpc_id            = aws_vpc.main.id
  cidr_block        = "172.31.34.0/26"
  availability_zone = "${var.aws_region}a"
  tags = {
    Name = "${var.application}-${var.environment}-private-${var.aws_region}a"
  }
}

resource "aws_subnet" "sp2" {
  // Private subnet 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "172.31.34.64/26"
  availability_zone = "${var.aws_region}b"
  tags = {
    Name = "${var.application}-${var.environment}-private-${var.aws_region}b"
  }
}

resource "aws_subnet" "sp3" {
  // Private subnet 3
  vpc_id            = aws_vpc.main.id
  cidr_block        = "172.31.34.128/26"
  availability_zone = "${var.aws_region}c"
  tags = {
    Name = "${var.application}-${var.environment}-private-${var.aws_region}c"
  }
}

resource "aws_route_table" "private" {
  // Private route table
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.application}-${var.environment}-private"
  }
}

resource "aws_route_table_association" "priv1" {
  // Route table association for private subnet 1
  subnet_id      = aws_subnet.sp1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "priv2" {
  // Route table association for private subnet 2
  subnet_id      = aws_subnet.sp2.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "priv3" {
  // Route table association for private subnet 3
  subnet_id      = aws_subnet.sp3.id
  route_table_id = aws_route_table.private.id
}

resource "aws_main_route_table_association" "main" {
  // Main route table association
  vpc_id         = aws_vpc.main.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "sg" {
  // Security group for the application
  name        = "${var.application}-${var.environment}"
  description = "${var.application}-${var.environment}"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name      = "${var.application}-${var.environment}"
    Component = "web_public"
  }
}

resource "aws_security_group_rule" "https" {
  // Ingress rule for HTTPS traffic within the security group
  type                     = "ingress"
  description              = "Ingress Allow 443"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.sg.id
  security_group_id        = aws_security_group.sg.id
}

resource "aws_security_group_rule" "https_ingress_all" {
  // Ingress rule for HTTPS traffic from all sources
  type              = "ingress"
  description       = "Ingress Allow 443 to All"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg.id
}

resource "aws_security_group_rule" "https_egress" {
  // Egress rule for HTTPS traffic within the security group
  type                     = "egress"
  description              = "Egress Allow HTTPS"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.sg.id
  security_group_id        = aws_security_group.sg.id
}

resource "aws_security_group_rule" "https_egress_all" {
  // Egress rule for HTTPS traffic to all destinations
  type              = "egress"
  description       = "Egress Allow HTTPS to All"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg.id
}

resource "aws_vpc_endpoint" "api" {
  // VPC endpoint for API Gateway
  vpc_id            = aws_vpc.main.id
  vpc_endpoint_type = "Interface"
  service_name      = "com.amazonaws.${data.aws_region.current.id}.execute-api"
  subnet_ids        = [join("", aws_subnet.sp1.*.id), join("", aws_subnet.sp2.*.id), join("", aws_subnet.sp3.*.id)]
  tags = {
    Name = "${var.application}-${var.environment}-api-endpoint"
  }
  security_group_ids = [aws_security_group.sg.id]
}