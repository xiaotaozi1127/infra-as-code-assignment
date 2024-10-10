resource "aws_api_gateway_rest_api" "register_user_api" {
  name        = "register-user-api"
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
}

resource "aws_api_gateway_integration_response" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.register_user_api.id
  resource_id = aws_api_gateway_rest_api.register_user_api.root_resource_id
  http_method = aws_api_gateway_method.proxy.http_method
  status_code = aws_api_gateway_method_response.proxy.status_code

  depends_on = [
    aws_api_gateway_method.proxy,
    aws_api_gateway_integration.lambda_integration
  ]
}

resource "aws_api_gateway_deployment" "register_user_api_deployment" {
  depends_on = [aws_api_gateway_integration.lambda_integration]
  rest_api_id = aws_api_gateway_rest_api.register_user_api.id
  stage_name  = "default"
}

output "api_gateway_register_user_invoke_url" {
  value = aws_api_gateway_deployment.register_user_api_deployment.invoke_url
}
