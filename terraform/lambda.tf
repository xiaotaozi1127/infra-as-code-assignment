resource "aws_lambda_function" "functions" {
  count = length(var.functions)

  function_name = var.functions[count.index].name

  s3_bucket = module.s3_bucket.s3_bucket_id
  s3_key    = var.functions[count.index].name

  runtime = "python3.10"
  handler = "lambda_handler"

  # Define environment variables
  environment {
    variables = {
      WEBSITE_S3    = format("%s-website-bucket", var.prefix)
      DB_TABLE_NAME = format("%s-user-info-table", var.prefix)
    }
  }
  # Path to the pre-created ZIP file
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

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
