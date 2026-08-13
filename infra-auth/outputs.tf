output "lambda_function_name" {
  description = "Nome da função Lambda de autenticação"
  value       = aws_lambda_function.auth.function_name
}