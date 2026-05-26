resource "aws_lambda_function" "lambda_function" {
  function_name    = var.function_name
  publish          = var.publish
  role             = var.role
  timeout          = var.timeout
  handler          = var.handler
  runtime          = var.runtime
  filename         = var.filename
  source_code_hash = var.source_code_hash
}

resource "aws_lambda_alias" "lambda_alias" {
  name             = var.alias_name
  description      = "Points to version ${aws_lambda_function.lambda_function.version}"
  function_name    = aws_lambda_function.lambda_function.arn
  function_version = aws_lambda_function.lambda_function.version
}