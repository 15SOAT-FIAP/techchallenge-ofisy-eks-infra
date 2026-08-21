########################################
# LAMBDA - CUSTOMERS AUTH AUTHORIZER
#
# So confere assinatura/expiracao/issuer do token - nao consulta o
# Postgres, entao dispensa vpc_config e Security Group (diferente da
# Lambda de emissao do token, em lambda.tf).
########################################

resource "aws_lambda_function" "auth_authorizer" {
  function_name = local.authorizer_function_name
  role          = "arn:aws:iam::${var.account_id}:role/${var.role_name}"

  package_type = "Image"
  image_uri    = "${data.aws_ecr_repository.auth_authorizer.repository_url}:${var.authorizer_image_tag}"

  architectures = ["arm64"]

  timeout     = 5
  memory_size = 128

  reserved_concurrent_executions = 10

  environment {
    variables = {
      JWT_SECRET = var.jwt_secret
    }
  }

  tags = {
    Name = local.authorizer_function_name
  }

  # O deploy da lambda é feito pelo CD do repo de auth via `aws lambda update-function-code`
  # Sem isso, o próximo apply reverte a lambda pra tag definida no terraform.tfvars
  lifecycle {
    ignore_changes = [image_uri]
  }
}
