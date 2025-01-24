variable "environment" {
  type    = string
  default = "dev"
}

variable "application" {
  type        = string
  description = "project application name"
  default     = "tao"
}

variable "aws_region" {
  type        = string
  default     = "eu-west-1"
  description = "AWS Region"
}