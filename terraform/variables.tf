variable "aws_profile" {
  default = "default"
}

variable "aws_region" {
  type    = string
  default = "eu-west-2"
}

variable "environment" {
  type = string
}

locals {
  bucket_name = "ssdp-ingestion-bucket-${var.environment}"
}