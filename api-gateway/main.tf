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

data "aws_lambda_function" "authorizer" {
  function_name = var.auth_authorizer_lambda_name
}

resource "aws_apigatewayv2_api" "ofisy_gateway" {
  name          = "${local.project_name}-api-gateway"
  protocol_type = "HTTP"
  description   = "Gateway publico da aplicacao Ofisy - expoe /auth/customers e repassa as demais rotas para o app no EKS"
}

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

resource "aws_apigatewayv2_integration" "quote_approve_proxy" {
  api_id                 = aws_apigatewayv2_api.ofisy_gateway.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "PATCH"
  integration_uri        = "http://${var.nlb_dns_name}:8080/api/v1/service-orders/quote/{id}/approve"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_integration" "quote_reprove_proxy" {
  api_id                 = aws_apigatewayv2_api.ofisy_gateway.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "PATCH"
  integration_uri        = "http://${var.nlb_dns_name}:8080/api/v1/service-orders/quote/{id}/reprove"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_integration" "default_proxy" {
  api_id                 = aws_apigatewayv2_api.ofisy_gateway.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  integration_uri        = "http://${var.nlb_dns_name}:8080/{proxy}"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_integration" "notifications_service_orders_proxy" {
  api_id                 = aws_apigatewayv2_api.ofisy_gateway.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "GET"
  integration_uri        = "http://${var.nlb_dns_name}:8080/api/v1/notifications/service-orders"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_integration" "notifications_service_orders_unread_proxy" {
  api_id                 = aws_apigatewayv2_api.ofisy_gateway.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "GET"
  integration_uri        = "http://${var.nlb_dns_name}:8080/api/v1/notifications/service-orders/unread"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_authorizer" "customers_token" {
  api_id                             = aws_apigatewayv2_api.ofisy_gateway.id
  authorizer_type                    = "REQUEST"
  authorizer_uri                     = data.aws_lambda_function.authorizer.invoke_arn
  identity_sources                   = ["$request.header.Authorization"]
  name                               = "${local.project_name}-customers-authorizer"
  authorizer_payload_format_version  = "2.0"
  enable_simple_responses            = true
}

resource "aws_lambda_permission" "allow_apigw_invoke_auth" {
  statement_id  = "AllowAPIGatewayInvokeAuth"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.auth.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.ofisy_gateway.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_apigw_invoke_authorizer" {
  statement_id  = "AllowAPIGatewayInvokeAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.authorizer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.ofisy_gateway.execution_arn}/*/*"
}

resource "aws_apigatewayv2_route" "auth_customers" {
  api_id    = aws_apigatewayv2_api.ofisy_gateway.id
  route_key = "POST /auth/customers"
  target    = "integrations/${aws_apigatewayv2_integration.auth_integration.id}"
}

resource "aws_apigatewayv2_route" "service_order_status" {
  api_id             = aws_apigatewayv2_api.ofisy_gateway.id
  route_key          = "GET /api/v1/service-orders/{id}/status"
  target             = "integrations/${aws_apigatewayv2_integration.service_order_status_proxy.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.customers_token.id
}

resource "aws_apigatewayv2_route" "quote_approve" {
  api_id             = aws_apigatewayv2_api.ofisy_gateway.id
  route_key          = "PATCH /api/v1/service-orders/quote/{id}/approve"
  target             = "integrations/${aws_apigatewayv2_integration.quote_approve_proxy.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.customers_token.id
}

resource "aws_apigatewayv2_route" "quote_reprove" {
  api_id             = aws_apigatewayv2_api.ofisy_gateway.id
  route_key          = "PATCH /api/v1/service-orders/quote/{id}/reprove"
  target             = "integrations/${aws_apigatewayv2_integration.quote_reprove_proxy.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.customers_token.id
}

resource "aws_apigatewayv2_route" "default_proxy" {
  api_id    = aws_apigatewayv2_api.ofisy_gateway.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.default_proxy.id}"
}

resource "aws_apigatewayv2_route" "notifications_service_orders" {
  api_id    = aws_apigatewayv2_api.ofisy_gateway.id
  route_key = "GET /api/v1/notifications/service-orders"
  target    = "integrations/${aws_apigatewayv2_integration.notifications_service_orders_proxy.id}"
}

resource "aws_apigatewayv2_route" "notifications_service_orders_unread" {
  api_id    = aws_apigatewayv2_api.ofisy_gateway.id
  route_key = "GET /api/v1/notifications/service-orders/unread"
  target    = "integrations/${aws_apigatewayv2_integration.notifications_service_orders_unread_proxy.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.ofisy_gateway.id
  name        = "$default"
  auto_deploy = true
}