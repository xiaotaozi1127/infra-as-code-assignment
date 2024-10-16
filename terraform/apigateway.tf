resource "aws_api_gateway_rest_api" "apis" {
  count = length(var.functions)

  name        = format("%s_%s_api", var.prefix, var.functions[count.index].name)
  description = "API for ${var.functions[count.index].name}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  lifecycle {
    // CloudFormation creates a new API Gateway first and then will delete the old one automatically.
    create_before_destroy = true
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

  #checkov:skip=CKV2_AWS_53:Ensure AWS API gateway request is validated
  rest_api_id      = aws_api_gateway_rest_api.apis[count.index].id
  resource_id      = local.api_resource_ids[count.index]
  http_method      = var.functions[count.index].method
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_api_key" "api_key" {
  name        = "ApiKey"
  description = "API key for accessing the API"
  enabled     = true
}

resource "aws_api_gateway_usage_plan" "usage_plan" {
  depends_on  = [aws_api_gateway_stage.stages]
  name        = "UsagePlan"
  description = "Usage plan for the API"
  api_stages {
    api_id = aws_api_gateway_rest_api.apis[0].id
    stage  = var.stage_name # Specify your deployment stage
  }
  api_stages {
    api_id = aws_api_gateway_rest_api.apis[1].id
    stage  = var.stage_name
  }
}

resource "aws_api_gateway_usage_plan_key" "shared_usage_plan_key" {
  key_id        = aws_api_gateway_api_key.api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.usage_plan.id
}

resource "aws_api_gateway_method_settings" "all" {
  count       = length(var.functions)
  rest_api_id = aws_api_gateway_rest_api.apis[count.index].id
  stage_name  = aws_api_gateway_stage.stages[count.index].stage_name
  method_path = "*/*"

  #checkov:skip=CKV_AWS_225:Ensure API Gateway method setting caching is enabled
  settings {
    logging_level        = "INFO"
    metrics_enabled      = true
    data_trace_enabled   = false //If Data Trace is enabled, it could pose a security risk as it allows verbose logging of all data between the client and server.
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
  //creates a new deployment first and then will delete the old one automatically.
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  count = length(var.functions)

  #checkov:skip=CKV_AWS_158:Ensure that CloudWatch Log Group is encrypted by KMS

  # AWS API Gateway automatically creates log groups following this naming convention when you enable logging for your API.
  # If you create a custom log group with a different name, API Gateway may not send logs to that group, leading to missing logs.
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.apis[count.index].id}/${var.stage_name}"
  retention_in_days = 365 # CloudWatch log groups must retain logs for a minimum duration of one year
}

# A stage represents a version of the API and allows you to manage multiple versions of your API
resource "aws_api_gateway_stage" "stages" {
  count = length(var.functions)

  #checkov:skip=CKV2_AWS_29:Ensure public API gateway are protected by WAF
  #checkov:skip=CKV2_AWS_51:Ensure AWS API Gateway endpoints uses client certificate authentication
  #checkov:skip=CKV2_AWS_53:Ensure AWS API gateway request is validated
  #checkov:skip=CKV_AWS_120:Ensure API Gateway caching is enabled
  //With tracing enabled X-Ray can provide an end-to-end view of an entire HTTP request
  xray_tracing_enabled = true
  stage_name            = var.stage_name
  rest_api_id           = aws_api_gateway_rest_api.apis[count.index].id
  deployment_id         = aws_api_gateway_deployment.deployment[count.index].id

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs[count.index].arn
    format          = "$context.identity.sourceIp - $context.identity.caller - $context.identity.user - $context.requestId - $context.httpMethod - $context.resourcePath - $context.status - $context.responseLength - $context.requestTime"
  }
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

  #checkov:skip=CKV_AWS_290:Ensure IAM policies does not allow write access without constraints
  #checkov:skip=CKV_AWS_355:Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions
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



