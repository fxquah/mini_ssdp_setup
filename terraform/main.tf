terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}


resource "aws_lambda_layer_version" "pyspy" {
  filename            = "layers/py-spy-layer.zip"
  layer_name          = "py-spy"
  compatible_runtimes = ["python3.11"]
}

resource "aws_lambda_function" "my_lambda" {
  # ...existing config...
  layers = [aws_lambda_layer_version.pyspy.arn]

  environment {
    variables = {
      ENABLE_PYSPY        = "0"   # flip to "1" without redeploying
      PYSPY_S3_BUCKET     = aws_s3_bucket.profiles.bucket
    }
  }
}