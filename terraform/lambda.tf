
resource "aws_iam_role" "trigger_ingestion_exec" {
  name = "ssdp-trigger-ingestion-exec-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "trigger_ingestion_basic" {
  role       = aws_iam_role.trigger_ingestion_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

module "trigger_ingestion" {
  source = "./modules/lambda_external"

  function_name = "ssdp-trigger-ingestion-${var.environment}"
  role          = aws_iam_role.trigger_ingestion_exec.arn
  handler       = "handler.handler"
  runtime       = "python3.12"
}
