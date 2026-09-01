variable "aws_region" {
  description = "Regiao da AWS onde o API Gateway sera criado"
  type        = string
  default     = "us-east-1"
}

variable "nlb_listener_arn" {
  description = <<-EOT
    ARN do Listener (porta 8080) do NLB interno criado pelo Service (type:
    LoadBalancer) do Kubernetes. Como o NLB e criado pelo Kubernetes, e nao
    pelo Terraform, esse ARN precisa ser obtido manualmente apos o deploy
    do app:

      NLB_DNS=$(kubectl get svc ofisy-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
      NLB_ARN=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?DNSName=='$NLB_DNS'].LoadBalancerArn" --output text)
      aws elbv2 describe-listeners --load-balancer-arn $NLB_ARN --query "Listeners[?Port==\`8080\`].ListenerArn" --output text
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