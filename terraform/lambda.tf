data "archive_file" "trigger_ingestion_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_src"
  output_path = "${path.module}/lambda_src/handler.zip"
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

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = module.trigger_ingestion.lambda_function_name
  # qualifier     = module.trigger_ingestion.lambda_alias_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.main.arn
}

resource "aws_s3_bucket_notification" "trigger" {
  bucket = aws_s3_bucket.main.id

  lambda_function {
    lambda_function_arn = module.trigger_ingestion.lambda_function_arn # tweak
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "trigger.json"
  }

  depends_on = [aws_lambda_permission.allow_s3]
}
