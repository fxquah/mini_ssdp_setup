data "archive_file" "trigger_ingestion_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_src"
  output_path = "${path.module}/lambda_src/handler.zip"
}

# Separate lambda — code is deployed independently via business_logic/Makefile,
# not through Terraform. Terraform owns the infra; the business logic team owns the code.
data "archive_file" "trigger_ingestion_separate_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../business_logic/trigger_ingestion"
  output_path = "${path.module}/../business_logic/trigger_ingestion/handler.zip"
}

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
  source = "./modules/lambda"

  function_name    = "ssdp-trigger-ingestion-${var.environment}"
  role             = aws_iam_role.trigger_ingestion_exec.arn
  handler          = "handler.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.trigger_ingestion_zip.output_path
  source_code_hash = data.archive_file.trigger_ingestion_zip.output_base64sha256
}

resource "aws_iam_role" "trigger_ingestion_separate_exec" {
  name = "ssdp-trigger-ingestion-separate-exec-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "trigger_ingestion_separate_basic" {
  role       = aws_iam_role.trigger_ingestion_separate_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

module "trigger_ingestion_separate" {
  source = "./modules/lambda"

  function_name    = "ssdp-trigger-ingestion-separate-${var.environment}"
  role             = aws_iam_role.trigger_ingestion_separate_exec.arn
  handler          = "handler.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.trigger_ingestion_separate_zip.output_path
  source_code_hash = data.archive_file.trigger_ingestion_separate_zip.output_base64sha256
}
