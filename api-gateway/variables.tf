variable "aws_region" {
  description = "Regiao da AWS onde o API Gateway sera criado"
  type        = string
  default     = "us-east-1"
}

variable "nlb_dns_name" {
  description = <<-EOT
    DNS publico do NLB criado pelo Service (type: LoadBalancer) do Kubernetes,
    no repositorio da aplicacao. Obtenha com:
      kubectl get svc ofisy-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
    So existe DEPOIS que o k8s/service.yml ja foi aplicado no cluster - por isso
    este e um estagio Terraform separado de infra/ e infra-auth/, aplicado
    manualmente depois dos dois.
  EOT
  type        = string
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
