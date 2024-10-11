resource "aws_lambda_function" "functions" {
  depends_on = [module.s3_bucket, aws_dynamodb_table.user-info-table, aws_iam_role.lambda_exec]
  count = length(var.functions)

  function_name = format("%s_%s", var.prefix, var.functions[count.index].name)
  timeout       = 30  # Set the timeout to 30 seconds, default value is 3 seconds
  runtime       = "python3.10"
  # The handler name in AWS Lambda should be specified in the format: <filename>.<function_name>
  handler = format("%s.lambda_handler", var.functions[count.index].name)

  # Define environment variables
  environment {
    variables = {
      WEBSITE_S3    = format("%s-website-bucket", var.prefix)
      DB_TABLE_NAME = format("%s-user-info-table", var.prefix)
    }
  }
  # Path to the pre-created ZIP file
  # Make sure your ZIP file is structured correctly.
  # The handler file must be at the root level of the ZIP file, not nested within another directory.
  filename = format("../%s.zip", var.functions[count.index].name)

  source_code_hash = filebase64sha256(format("../%s.zip", var.functions[count.index].name))
  role             = aws_iam_role.lambda_exec.arn
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

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

  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.functions[count.index].function_name
  principal     = "apigateway.amazonaws.com"

  # The source ARN for the permission
  source_arn = "${aws_api_gateway_rest_api.register_user_api.execution_arn}/*/*"
}

resource "aws_iam_policy" "dynamodb_manage_item" {
  name        = "DynamoDBManageItemPolicy"
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

resource "aws_iam_policy" "website_bucket_permission" {
  name        = "WebsiteBucketPolicy"
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
  policy_arn = aws_iam_policy.dynamodb_manage_item.arn
}

resource "aws_iam_role_policy_attachment" "s3_policy" {
  depends_on = [aws_iam_role.lambda_exec]
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.website_bucket_permission.arn
}
