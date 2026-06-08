resource "aws_iam_role" "eventbridge_sfn" {
  name = "ssdp-eventbridge-sfn-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
    }]
  })
}


resource "aws_cloudwatch_event_rule" "s3_trigger_json" {
  name = "ssdp-s3-trigger-json-${var.environment}"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = { name = [aws_s3_bucket.main.id] }
      object = { key = ["trigger.json"] }
    }
  })
}

