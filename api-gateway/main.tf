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

data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["${local.project_name}-vpc"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  filter {
    name   = "tag:Name"
    values = ["${local.project_name}-private-subnet-*"]
  }
}

data "aws_security_group" "eks" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  filter {
    name   = "tag:Name"
    values = ["${local.project_name}-eks-sg"]
  }
}

########################################
# VPC LINK
########################################

resource "aws_security_group" "vpc_link" {
  name        = "${local.project_name}-api-gateway-vpc-link-sg"
  description = "Security Group das ENIs do VPC Link do API Gateway"
  vpc_id      = data.aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.project_name}-api-gateway-vpc-link-sg"
  }
}

resource "aws_security_group_rule" "eks_from_vpc_link" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.vpc_link.id
  security_group_id        = data.aws_security_group.eks.id
}

resource "aws_apigatewayv2_vpc_link" "ofisy" {
  name               = "${local.project_name}-vpc-link"
  security_group_ids = [aws_security_group.vpc_link.id]
  subnet_ids         = data.aws_subnets.private.ids
}

data "aws_lambda_function" "auth" {
  function_name = var.auth_lambda_name
}

data "aws_lambda_function" "authorizer" {
  function_name = var.auth_authorizer_lambda_name
}

########################################
# API GATEWAY (HTTP API)
########################################

resource "aws_apigatewayv2_api" "ofisy_gateway" {
  name          = "${local.project_name}-api-gateway"
  protocol_type = "HTTP"
  description   = "Gateway publico da aplicacao Ofisy - unico ponto de entrada, ja que o NLB agora e interno"
}

resource "aws_apigatewayv2_integration" "auth_integration" {
  api_id                 = aws_apigatewayv2_api.ofisy_gateway.id
  integration_type       = "AWS_PROXY"
  integration_uri        = data.aws_lambda_function.auth.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "nlb_proxy" {
  api_id                 = aws_apigatewayv2_api.ofisy_gateway.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.ofisy.id
  integration_uri        = var.nlb_listener_arn
  payload_format_version = "1.0"
}

########################################
# LAMBDA AUTHORIZER
########################################

resource "aws_apigatewayv2_authorizer" "customers_token" {
  api_id                             = aws_apigatewayv2_api.ofisy_gateway.id
  authorizer_type                    = "REQUEST"
  authorizer_uri                     = data.aws_lambda_function.authorizer.invoke_arn
  identity_sources                   = ["$request.header.Authorization"]
  name                               = "${local.project_name}-customers-authorizer"
  authorizer_payload_format_version  = "2.0"
  enable_simple_responses            = true
}

########################################
# PERMISSOES - autoriza o API Gateway a invocar as Lambdas do outro repo
########################################

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

########################################
# ROTAS
########################################

resource "aws_apigatewayv2_route" "auth_customers" {
  api_id    = aws_apigatewayv2_api.ofisy_gateway.id
  route_key = "POST /auth/customers"
  target    = "integrations/${aws_apigatewayv2_integration.auth_integration.id}"
}

resource "aws_apigatewayv2_route" "service_order_status" {
  api_id             = aws_apigatewayv2_api.ofisy_gateway.id
  route_key          = "GET /api/v1/service-orders/{id}/status"
  target             = "integrations/${aws_apigatewayv2_integration.nlb_proxy.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.customers_token.id
}

resource "aws_apigatewayv2_route" "quote_approve" {
  api_id             = aws_apigatewayv2_api.ofisy_gateway.id
  route_key          = "PATCH /api/v1/service-orders/quote/{id}/approve"
  target             = "integrations/${aws_apigatewayv2_integration.nlb_proxy.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.customers_token.id
}

resource "aws_apigatewayv2_route" "quote_reprove" {
  api_id             = aws_apigatewayv2_api.ofisy_gateway.id
  route_key          = "PATCH /api/v1/service-orders/quote/{id}/reprove"
  target             = "integrations/${aws_apigatewayv2_integration.nlb_proxy.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.customers_token.id
}

resource "aws_apigatewayv2_route" "notifications_service_orders" {
  api_id             = aws_apigatewayv2_api.ofisy_gateway.id
  route_key          = "GET /api/v1/notifications/service-orders"
  target             = "integrations/${aws_apigatewayv2_integration.nlb_proxy.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.customers_token.id
}

resource "aws_apigatewayv2_route" "notifications_service_orders_unread" {
  api_id             = aws_apigatewayv2_api.ofisy_gateway.id
  route_key          = "GET /api/v1/notifications/service-orders/unread"
  target             = "integrations/${aws_apigatewayv2_integration.nlb_proxy.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.customers_token.id
}

resource "aws_apigatewayv2_route" "notifications_service_order_by_id" {
  api_id             = aws_apigatewayv2_api.ofisy_gateway.id
  route_key          = "GET /api/v1/notifications/service-orders/{id}"
  target             = "integrations/${aws_apigatewayv2_integration.nlb_proxy.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.customers_token.id
}

resource "aws_apigatewayv2_route" "notifications_service_order_mark_read" {
  api_id             = aws_apigatewayv2_api.ofisy_gateway.id
  route_key          = "PATCH /api/v1/notifications/service-orders/{id}/read"
  target             = "integrations/${aws_apigatewayv2_integration.nlb_proxy.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.customers_token.id
}

resource "aws_apigatewayv2_route" "default_proxy" {
  api_id    = aws_apigatewayv2_api.ofisy_gateway.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.nlb_proxy.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.ofisy_gateway.id
  name        = "$default"
  auto_deploy = true
}