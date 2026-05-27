resource "aws_s3_bucket" "main" {
  bucket = local.bucket_name

  tags = {
    Environment = var.environment
  }
}

resource "aws_s3_bucket_notification" "main" {
  bucket      = aws_s3_bucket.main.id
  eventbridge = true
}