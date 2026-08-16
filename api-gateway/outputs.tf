output "api_gateway_invoke_url" {
  description = "URL publica do API Gateway"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "auth_lambda_arn" {
  description = "ARN da funcao Lambda de emissao do token via CPF/CNPJ, conforme resolvida pelo data source"
  value       = data.aws_lambda_function.auth.arn
}
