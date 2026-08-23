terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  project_name = "ofisy"
}

data "aws_lambda_function" "auth" {
  function_name = var.auth_lambda_name
}

resource "aws_apigatewayv2_api" "ofisy_gateway" {
  name          = "${local.project_name}-api-gateway"
  protocol_type = "HTTP"
  description   = "Gateway publico da aplicacao Ofisy - expoe /auth/customers e repassa as demais rotas para o app no EKS"
}

# Integracao AWS_PROXY com a Lambda que emite o token via CPF/CNPJ
resource "aws_apigatewayv2_integration" "auth_integration" {
  api_id                 = aws_apigatewayv2_api.ofisy_gateway.id
  integration_type       = "AWS_PROXY"
  integration_uri        = data.aws_lambda_function.auth.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "service_order_status_proxy" {
  api_id                 = aws_apigatewayv2_api.ofisy_gateway.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "GET"
  integration_uri        = "http://${var.nlb_dns_name}:8080/api/v1/service-orders/{id}/status"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_integration" "default_proxy" {
  api_id                 = aws_apigatewayv2_api.ofisy_gateway.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  integration_uri        = "http://${var.nlb_dns_name}:8080/{proxy}"
  payload_format_version = "1.0"
}

resource "aws_lambda_permission" "allow_apigw_invoke_auth" {
  statement_id  = "AllowAPIGatewayInvokeAuth"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.auth.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.ofisy_gateway.execution_arn}/*/*"
}

resource "aws_apigatewayv2_route" "auth_customers" {
  api_id    = aws_apigatewayv2_api.ofisy_gateway.id
  route_key = "POST /auth/customers"
  target    = "integrations/${aws_apigatewayv2_integration.auth_integration.id}"
}

resource "aws_apigatewayv2_route" "service_order_status" {
  api_id    = aws_apigatewayv2_api.ofisy_gateway.id
  route_key = "GET /api/v1/service-orders/{id}/status"
  target    = "integrations/${aws_apigatewayv2_integration.service_order_status_proxy.id}"
}

resource "aws_apigatewayv2_route" "default_proxy" {
  api_id    = aws_apigatewayv2_api.ofisy_gateway.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.default_proxy.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.ofisy_gateway.id
  name        = "$default"
  auto_deploy = true
}
