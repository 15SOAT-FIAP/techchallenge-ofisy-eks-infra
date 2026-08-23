output "lambda_function_name" {
  description = "Nome da função Lambda de autenticação"
  value       = aws_lambda_function.auth.function_name
}

output "auth_authorizer_function_name" {
  description = "Nome da função Lambda Authorizer - usar como auth_authorizer_lambda_name no módulo api-gateway"
  value       = aws_lambda_function.auth_authorizer.function_name
}