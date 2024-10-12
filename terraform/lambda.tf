resource "aws_lambda_function" "functions" {
  depends_on = [module.s3_bucket, aws_dynamodb_table.user-info-table, aws_iam_role.lambda_exec]
  count      = length(var.functions)

  #checkov:skip=CKV_AWS_117:Ensure that AWS Lambda function is configured inside a VPC
  #checkov:skip=CKV_AWS_116:Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ)
  #checkov:skip=CKV_AWS_173:Check encryption settings for Lambda environmental variable
  #checkov:skip=CKV_AWS_272:Ensure AWS Lambda function is configured to validate code-signing
  function_name = format("%s_%s", var.prefix, var.functions[count.index].name)
  timeout       = 30 # Set the timeout to 30 seconds, default value is 3 seconds
  runtime       = "python3.10"
  # The handler name in AWS Lambda should be specified in the format: <filename>.<function_name>
  handler = format("%s.lambda_handler", var.functions[count.index].name)
  //Adding concurrency limits can prevent a rapid spike in usage and costs, while also increasing or lowering the default concurrency limit.
  reserved_concurrent_executions = 100

  # Define environment variables
  environment {
    variables = {
      WEBSITE_S3    = format("%s-website-bucket", var.prefix)
      DB_TABLE_NAME = format("%s-user-info-table", var.prefix)
    }
  }

  tracing_config {
    mode = "Active"
  }
  # Path to the pre-created ZIP file
  # Make sure your ZIP file is structured correctly.
  # The handler file must be at the root level of the ZIP file, not nested within another directory.
  filename = format("../%s.zip", var.functions[count.index].name)

  source_code_hash = filebase64sha256(format("../%s.zip", var.functions[count.index].name))
  role             = aws_iam_role.lambda_exec.arn
}

resource "aws_iam_role" "lambda_exec" {
  name = format("%s_lambda_iam_role", var.prefix)

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_lambda_permission" "allow_api_gateway" {
  count = length(var.functions)

  statement_id  = "AllowExecutionFromAPIGateway${count.index}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.functions[count.index].function_name
  principal     = "apigateway.amazonaws.com"

  # The source ARN for the permission
  source_arn = "${aws_api_gateway_rest_api.apis[count.index].execution_arn}/*/*"
}

resource "aws_iam_policy" "allow_dynamodb" {
  name        = format("%s_dynamodb_policy", var.prefix)
  description = "Policy to allow DynamoDB access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
        ]
        Resource = aws_dynamodb_table.user-info-table.arn
      }
    ]
  })
}

resource "aws_iam_policy" "allow_website_bucket" {
  name        = format("%s_s3_policy", var.prefix)
  description = "Policy to allow S3 bucket access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
        ]
        Resource = "${module.s3_bucket.s3_bucket_arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  depends_on = [aws_iam_role.lambda_exec]
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "dynamodb_policy" {
  depends_on = [aws_iam_role.lambda_exec]
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.allow_dynamodb.arn
}

resource "aws_iam_role_policy_attachment" "s3_policy" {
  depends_on = [aws_iam_role.lambda_exec]
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.allow_website_bucket.arn
}

resource "aws_cloudwatch_log_group" "lambda_log_groups" {
  count             = length(var.functions)

  #checkov:skip=CKV_AWS_158:Ensure that CloudWatch Log Group is encrypted by KMS
  name              = "/aws/lambda/${aws_lambda_function.functions[count.index].function_name}"
  retention_in_days = 365 # Set the desired retention period
}
