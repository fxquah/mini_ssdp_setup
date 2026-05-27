resource "aws_iam_role" "sfn_exec" {
  name = "ssdp-sfn-exec-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "states.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "sfn_exec_policy" {
  name = "ssdp-sfn-exec-policy-${var.environment}"
  role = aws_iam_role.sfn_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "lambda:InvokeFunction"
        Resource = [
          module.trigger_ingestion.lambda_alias_arn,
          module.trigger_ingestion.lambda_function_arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogDelivery",
          "logs:PutLogEvents",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "etl_rd_state_machine" {
  name              = "/aws/state-machine/ssdp-etl-rd-${var.environment}"
  retention_in_days = 14
}

resource "aws_sfn_state_machine" "etl_rd" {
  name     = "ssdp-etl-rd-${var.environment}"
  role_arn = aws_iam_role.sfn_exec.arn
  publish  = true

  definition = templatefile("${path.module}/state-machine-definitions/etl-rd.asl.json", {
    TriggerIngestionLambda = module.trigger_ingestion.lambda_function_arn
  })

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.etl_rd_state_machine.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }
}
