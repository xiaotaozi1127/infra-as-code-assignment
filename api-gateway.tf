resource "aws_api_gateway_rest_api" "register_user_api" {
  name        = "register-user-api"
  description = "API Gateway for register user function"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.register_user_api.id
  parent_id   = aws_api_gateway_rest_api.register_user_api.root_resource_id
  path_part   = "{proxy+}"  # This enables the proxy integration
}

resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.register_user_api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"  # Allows all HTTP methods
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_proxy" {
  rest_api_id             = aws_api_gateway_rest_api.register_user_api.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.proxy.http_method
  integration_http_method = "POST"  # Lambda integration uses POST
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.functions[0].invoke_arn
}

resource "aws_api_gateway_deployment" "register_user_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.register_user_api.id
  stage_name  = "default"

  depends_on = [aws_api_gateway_integration.lambda_proxy]
}
