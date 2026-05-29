data "archive_file" "trigger_ingestion_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_src"
  output_path = "${path.module}/lambda_src/handler.zip"
}

data "archive_file" "pyspy_layer_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_layer"
  output_path = "${path.module}/lambda_layer.zip"
}

resource "aws_lambda_layer_version" "pyspy" {
  layer_name          = "py-spy-${var.environment}"
  filename            = data.archive_file.pyspy_layer_zip.output_path
  source_code_hash    = data.archive_file.pyspy_layer_zip.output_base64sha256
  compatible_runtimes = ["python3.12"]
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

resource "aws_iam_role_policy" "trigger_ingestion_pyspy_s3" {
  name = "pyspy-profile-upload"
  role = aws_iam_role.trigger_ingestion_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "s3:PutObject"
      Resource = "${aws_s3_bucket.main.arn}/profiles/*"
    }]
  })
}

module "trigger_ingestion" {
  source = "./modules/lambda"

  function_name    = "ssdp-trigger-ingestion-${var.environment}"
  role             = aws_iam_role.trigger_ingestion_exec.arn
  handler          = "handler.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.trigger_ingestion_zip.output_path
  source_code_hash = data.archive_file.trigger_ingestion_zip.output_base64sha256
  layers           = [aws_lambda_layer_version.pyspy.arn]

  environment_variables = {
    ENABLE_PYSPY    = "0"
    PYSPY_S3_BUCKET = local.bucket_name
  }
}