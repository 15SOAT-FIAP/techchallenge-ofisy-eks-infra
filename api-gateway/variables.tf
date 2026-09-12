variable "aws_region" {
  description = "Regiao da AWS onde o API Gateway sera criado"
  type        = string
  default     = "us-east-1"
}

variable "nlb_service_name" {
  description = <<-EOT
    Identificacao do Service do Kubernetes (no formato "namespace/nome") que
    cria o NLB interno da aplicacao, definido em k8s/service.yml do
    repositorio techchallenge-ofisy.

    O NLB e criado pelo Kubernetes, e nao pelo Terraform, entao o Listener
    :8080 usado pelo VPC Link e descoberto via data source pela tag
    "kubernetes.io/service-name" que o cloud provider grava no Load Balancer.
    Por isso o deploy da aplicacao precisa acontecer antes do apply deste
    module.
  EOT
  type        = string
  default     = "default/ofisy-service"
}

variable "nlb_listener_port" {
  description = "Porta do Listener do NLB interno para onde o API Gateway faz proxy (mesma porta declarada no Service do Kubernetes)"
  type        = number
  default     = 8080
}

variable "auth_lambda_name" {
  description = "Nome da funcao Lambda que valida CPF/CNPJ e emite o token (criada em infra-auth/lambda.tf). Deve ja existir no momento do apply."
  type        = string
  default     = "ofisy-auth"
}

variable "auth_authorizer_lambda_name" {
  description = <<-EOT
    Nome da funcao Lambda Authorizer, que valida o token nas rotas
    protegidas (repositorio techchallenge-ofisy-auth, entrypoint separado
    do de emissao do token). Deve ja existir no momento do apply.
  EOT
  type        = string
  default     = "ofisy-auth-authorizer"
}

variable "datadog_api_key" {
  description = "API Key do Datadog (sensivel). Mesma key usada pelo Agent em infra/"
  type        = string
  sensitive   = true
}

variable "datadog_app_key" {
  description = "Application Key do Datadog (sensivel), usada pelo provider Terraform para gerenciar o Synthetics Test via API"
  type        = string
  sensitive   = true
}

variable "datadog_site" {
  description = "Site do Datadog (ex.: datadoghq.com, us5.datadoghq.com)"
  type        = string
  default     = "us5.datadoghq.com"
}