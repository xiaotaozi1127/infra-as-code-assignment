output "website_bucket_arn" {
  value = module.s3_bucket.s3_bucket_arn
}

output "dynamodb_table_arn" {
  value = aws_dynamodb_table.user-info-table.arn
}

output "lambda_function_arn" {
  value       = [for function in aws_lambda_function.functions : function.invoke_arn]
}

output "api_gateway_invoke_url" {
  value = [for deployment in aws_api_gateway_deployment.deployment : deployment.invoke_url]
}


