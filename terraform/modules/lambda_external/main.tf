data "archive_file" "bootstrap_zip" {
  type        = "zip"
  source_file = "${path.module}/handler.py"
  output_path = "${path.module}/bootstrap.zip"
}

resource "aws_lambda_function" "lambda_function" {
  function_name    = var.function_name
  publish          = true
  role             = var.role
  timeout          = var.timeout
  handler          = var.handler
  runtime          = var.runtime
  filename         = data.archive_file.bootstrap_zip.output_path
  source_code_hash = data.archive_file.bootstrap_zip.output_base64sha256

  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}

resource "aws_lambda_alias" "lambda_alias" {
  name             = "${var.function_name}-${aws_lambda_function.lambda_function.version}"
  description      = "${var.function_name} version : ${aws_lambda_function.lambda_function.version}"
  function_name    = aws_lambda_function.lambda_function.arn
  function_version = aws_lambda_function.lambda_function.version
}
