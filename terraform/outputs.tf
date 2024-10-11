# Reference the outputs from the module
output "website_bucket_id" {
  value = module.s3_bucket.s3_bucket_id
}

output "dynamodb_table_id" {
  value = aws_dynamodb_table.user-info-table.id
}

output "lambda_function_arns" {
  description = "The ARNs for the lambda functions."
  value       = [for function in aws_lambda_function.functions : function.invoke_arn]
}

output "api_gateway_role_arn" {
  value = aws_iam_role.api_gateway_role.arn
}

output "api_gateway_register_user_invoke_url" {
  value = [for deployment in aws_api_gateway_deployment.deployment : deployment.invoke_url]
}


