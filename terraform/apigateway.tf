resource "aws_api_gateway_rest_api" "register_user_api" {
  name        = format("%s_register_user_api", var.prefix)
  description = "API Gateway for register user function"
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
  stage_name  = aws_api_gateway_stage.register_user_api_stage.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = true
    logging_level   = "INFO"
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

resource "aws_api_gateway_method_response" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.register_user_api.id
  resource_id = aws_api_gateway_rest_api.register_user_api.root_resource_id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = "200"
  //cors section
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.register_user_api.id
  resource_id = aws_api_gateway_rest_api.register_user_api.root_resource_id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = aws_api_gateway_method_response.proxy.status_code

  //cors
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" =  "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  depends_on = [
    aws_api_gateway_method.proxy,
    aws_api_gateway_integration.lambda_integration
  ]
}

resource "aws_api_gateway_deployment" "register_user_api_deployment" {
  depends_on = [aws_api_gateway_integration.lambda_integration]
  rest_api_id = aws_api_gateway_rest_api.register_user_api.id
  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.register_user_api.body))
  }
  lifecycle {
    create_before_destroy = true
  }
}

# Create a CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name = "${var.prefix}/apigateway/${aws_api_gateway_rest_api.register_user_api.name}"
  retention_in_days = 7  # Adjust retention period as needed
}

# Enable CloudWatch logging for your API Gateway stage
resource "aws_api_gateway_stage" "register_user_api_stage" {
  depends_on = [aws_cloudwatch_log_group.api_gateway_logs]
  rest_api_id = aws_api_gateway_rest_api.register_user_api.id
  stage_name  = "default"

  # Attach the logging role to the stage
  deployment_id = aws_api_gateway_deployment.register_user_api_deployment.id
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format          = jsonencode({
      requestId      = "$context.requestId",
      ip             = "$context.identity.sourceIp",
      requestTime    = "$context.requestTime",
      httpMethod     = "$context.httpMethod",
      resourcePath   = "$context.resourcePath",
      status         = "$context.status",
      protocol       = "$context.protocol",
      responseLength = "$context.responseLength"
    })
  }
}

output "api_gateway_register_user_invoke_url" {
  value = aws_api_gateway_deployment.register_user_api_deployment.invoke_url
}



