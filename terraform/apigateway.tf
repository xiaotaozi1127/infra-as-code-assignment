resource "aws_api_gateway_rest_api" "apis" {
  count = length(var.functions)

  name        = format("%s_%s_api", var.prefix, var.functions[count.index].name)
  description = "API for ${var.functions[count.index].name}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# For the root resource ('/') in AWS API Gateway, you do not explicitly create a resource for it;
resource "aws_api_gateway_resource" "register_resource" {
  rest_api_id = aws_api_gateway_rest_api.apis[0].id
  parent_id   = aws_api_gateway_rest_api.apis[0].root_resource_id
  path_part   = "register"
}

locals {
  api_resource_ids = [aws_api_gateway_resource.register_resource.id, aws_api_gateway_rest_api.apis[1].root_resource_id]
}

resource "aws_api_gateway_method" "methods" {
  count = length(var.functions)

  rest_api_id   = aws_api_gateway_rest_api.apis[count.index].id
  resource_id   = local.api_resource_ids[count.index]
  http_method   = var.functions[count.index].method
  authorization = "NONE"
}

resource "aws_api_gateway_method_settings" "all" {
  count       = length(var.functions)
  rest_api_id = aws_api_gateway_rest_api.apis[count.index].id
  stage_name  = aws_api_gateway_stage.stages[count.index].stage_name
  method_path = "*/*"

  settings {
    logging_level      = "INFO"
    metrics_enabled    = true
    data_trace_enabled = true
  }
}

//In Lambda proxy integration, set the integration's HTTP method to POST,
//the integration endpoint URI to the ARN of the Lambda function invocation action of a specific Lambda function,
//and grant API Gateway permission to call the Lambda function on your behalf.
resource "aws_api_gateway_integration" "lambda_integration" {
  count                   = length(var.functions)
  rest_api_id             = aws_api_gateway_rest_api.apis[count.index].id
  resource_id             = local.api_resource_ids[count.index]
  http_method             = aws_api_gateway_method.methods[count.index].http_method
  integration_http_method = "POST" //you must use POST for Lambda proxy integration
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.functions[count.index].invoke_arn
}

resource "aws_api_gateway_deployment" "deployment" {
  count       = length(var.functions)
  depends_on  = [aws_api_gateway_integration.lambda_integration]
  rest_api_id = aws_api_gateway_rest_api.apis[count.index].id
  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.apis[count.index].body))
  }
}

# Customized the retention days for default log group
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  count = length(var.functions)

  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.apis[count.index].id}/${var.stage_name}"
  retention_in_days = 7 # Adjust retention period as needed
}

# A stage represents a version of the API and allows you to manage multiple versions of your API
resource "aws_api_gateway_stage" "stages" {
  count = length(var.functions)

  stage_name    = var.stage_name
  rest_api_id   = aws_api_gateway_rest_api.apis[count.index].id
  deployment_id = aws_api_gateway_deployment.deployment[count.index].id
}

resource "aws_iam_role" "api_gateway_role" {
  name = format("%s_api_gateway_role", var.prefix)

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
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

resource "aws_api_gateway_account" "demo" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_role.arn
}



