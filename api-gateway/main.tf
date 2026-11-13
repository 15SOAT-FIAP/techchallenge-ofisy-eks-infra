terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    datadog = {
      source  = "DataDog/datadog"
      version = "~> 3.55"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "datadog" {
  api_key = var.datadog_api_key
  app_key = var.datadog_app_key
  api_url = "https://api.${var.datadog_site}/"
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

########################################
# NLB INTERNO - um por microsservico
########################################

data "aws_lb" "service" {
  for_each = var.nlb_service_names

  tags = {
    "kubernetes.io/service-name" = each.value
  }
}

data "aws_lb_listener" "service" {
  for_each = var.nlb_service_names

  load_balancer_arn = data.aws_lb.service[each.key].arn
  port              = var.nlb_listener_port
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
  for_each = var.nlb_service_names

  api_id                 = aws_apigatewayv2_api.ofisy_gateway.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.ofisy.id
  integration_uri        = data.aws_lb_listener.service[each.key].arn
  payload_format_version = "1.0"
}

# Mesma integracao do nlb_proxy, mas sobrescrevendo X-Customer-Id com o
# customerId do Lambda Authorizer. So para servicos com rota customer_header.
resource "aws_apigatewayv2_integration" "nlb_proxy_customer" {
  for_each = toset([for route in local.service_routes : route.service if try(route.customer_header, false)])

  api_id                 = aws_apigatewayv2_api.ofisy_gateway.id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.ofisy.id
  integration_uri        = data.aws_lb_listener.service[each.key].arn
  payload_format_version = "1.0"
  request_parameters = {
    "overwrite:header.X-Customer-Id" = "$context.authorizer.customerId"
  }
}

########################################
# LAMBDA AUTHORIZER
########################################

resource "aws_apigatewayv2_authorizer" "customers_token" {
  api_id                            = aws_apigatewayv2_api.ofisy_gateway.id
  authorizer_type                   = "REQUEST"
  authorizer_uri                    = data.aws_lambda_function.authorizer.invoke_arn
  identity_sources                  = ["$request.header.Authorization"]
  name                              = "${local.project_name}-customers-authorizer"
  authorizer_payload_format_version = "2.0"
  enable_simple_responses           = true
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

# Rota -> microsservico que atende, e se exige o token do cliente.
# O que nao casar com nenhuma rota cai no ANY /{proxy+}, que vai pro core.
# Enquanto um servico nao for extraido do core (com Service/NLB proprio e
# entrada em var.nlb_service_names), as rotas dele continuam aqui no core.
# customer_header (opcional, exige protected) repassa o customerId do
# authorizer no header X-Customer-Id.
locals {
  service_routes = {
    "ANY /{proxy+}"                                        = { service = "core", protected = false }
    "GET /api/v1/service-orders/{id}/status"               = { service = "core", protected = true }
    "PATCH /api/v1/service-orders/quote/{id}/approve"      = { service = "core", protected = true }
    "PATCH /api/v1/service-orders/quote/{id}/reprove"      = { service = "core", protected = true }
    "GET /api/v1/notifications/service-orders"             = { service = "notification", protected = true, customer_header = true }
    "GET /api/v1/notifications/service-orders/unread"      = { service = "notification", protected = true, customer_header = true }
    "GET /api/v1/notifications/service-orders/{id}"        = { service = "notification", protected = true, customer_header = true }
    "PATCH /api/v1/notifications/service-orders/{id}/read" = { service = "notification", protected = true, customer_header = true }
  }
}

resource "aws_apigatewayv2_route" "service" {
  for_each = local.service_routes

  api_id             = aws_apigatewayv2_api.ofisy_gateway.id
  route_key          = each.key
  target             = "integrations/${try(each.value.customer_header, false) ? aws_apigatewayv2_integration.nlb_proxy_customer[each.value.service].id : aws_apigatewayv2_integration.nlb_proxy[each.value.service].id}"
  authorization_type = each.value.protected ? "CUSTOM" : "NONE"
  authorizer_id      = each.value.protected ? aws_apigatewayv2_authorizer.customers_token.id : null
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.ofisy_gateway.id
  name        = "$default"
  auto_deploy = true
}
