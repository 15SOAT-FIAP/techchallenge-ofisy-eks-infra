output "api_gateway_invoke_url" {
  description = "URL publica do API Gateway"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "vpc_link_id" {
  description = "ID do VPC Link, caso precise depurar conectividade"
  value       = aws_apigatewayv2_vpc_link.ofisy.id
}

output "auth_lambda_arn" {
  description = "ARN da funcao Lambda de emissao do token via CPF/CNPJ, conforme resolvida pelo data source"
  value       = data.aws_lambda_function.auth.arn
}

output "auth_authorizer_lambda_arn" {
  description = "ARN da funcao Lambda Authorizer, conforme resolvida pelo data source"
  value       = data.aws_lambda_function.authorizer.arn
}