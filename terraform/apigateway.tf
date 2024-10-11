resource "aws_api_gateway_rest_api" "register_user_api" {
  name        = format("%s_register_user_api", var.prefix)
  description = "API Gateway for register user function"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# For the root resource ('/') in AWS API Gateway, you do not explicitly create a resource for it in Terraform;
# Instead, you directly associate methods with the API itself.
resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.register_user_api.id
  resource_id   = aws_api_gateway_rest_api.register_user_api.root_resource_id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.register_user_api.id
  stage_name  = aws_api_gateway_stage.default.stage_name
  method_path = "*/*"

  settings {
    logging_level   = "INFO"
    metrics_enabled = true
    data_trace_enabled = true
  }
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.register_user_api.id
  resource_id             = aws_api_gateway_rest_api.register_user_api.root_resource_id
  http_method             = aws_api_gateway_method.proxy.http_method
  integration_http_method = "POST"  # Lambda integration uses POST
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.functions[0].invoke_arn
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [aws_api_gateway_integration.lambda_integration]
  rest_api_id = aws_api_gateway_rest_api.register_user_api.id
  stage_name = var.stage_name
  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.register_user_api.body))
  }
}

# Create a CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.register_user_api.id}/${var.stage_name}"
  retention_in_days = 7  # Adjust retention period as needed
}

# Enable CloudWatch logging for your API Gateway stage
resource "aws_api_gateway_stage" "default" {
  depends_on = [aws_cloudwatch_log_group.api_gateway_logs]
  stage_name  = var.stage_name
  rest_api_id = aws_api_gateway_rest_api.register_user_api.id
  deployment_id = aws_api_gateway_deployment.deployment.id
  role_arn = aws_iam_role.api_gateway_role.arn

  # Attach the logging role to the stage
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format          = "$context.requestId $context.status $context.responseLength"
  }
}

resource "aws_iam_role" "api_gateway_role" {
  name = format("%s_api_gateway_role", var.prefix)

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "api_gateway_logging_policy" {
  name        = format("%s_api_gateway_logging_policy", var.prefix)
  description = "Policy to allow API Gateway to log to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_logging_policy" {
  role       = aws_iam_role.api_gateway_role.name
  policy_arn = aws_iam_policy.api_gateway_logging_policy.arn
}



