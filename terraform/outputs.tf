output "lambda_function_arns" {
  description = "The ARNs for the lambda functions."
  value       = [for function in aws_lambda_function.functions : function.invoke_arn]
}

output "api_gateway_register_user_invoke_url" {
  value = aws_api_gateway_deployment.register_user_api_deployment.invoke_url
}
