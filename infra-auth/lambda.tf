########################################
# LAMBDA - CUSTOMERS AUTH
########################################

resource "aws_lambda_function" "auth" {
  function_name = local.function_name
  role          = "arn:aws:iam::${var.account_id}:role/${var.role_name}"

  package_type = "Image"
  image_uri    = "${data.aws_ecr_repository.auth.repository_url}:${var.image_tag}"

  architectures = ["arm64"]

  timeout     = 15
  memory_size = 512

  reserved_concurrent_executions = 10

  vpc_config {
    subnet_ids         = data.aws_subnets.private.ids
    security_group_ids = [data.aws_security_group.lambda_auth.id]
  }

  environment {
    variables = {
      POSTGRES_HOST     = data.aws_db_instance.main.address
      POSTGRES_PORT     = data.aws_db_instance.main.port
      POSTGRES_DB       = data.aws_db_instance.main.db_name
      POSTGRES_USER     = data.aws_db_instance.main.master_username
      POSTGRES_PASSWORD = var.db_password
      POSTGRES_SSL_MODE = "require"
      JWT_SECRET        = var.jwt_secret
      JWT_EXPIRATION    = var.jwt_expiration
    }
  }

  tags = {
    Name = local.function_name
  }

  # O deploy da lambda é feito pelo CD do repo de auth via aws lambda update-function-code`
  # Sem isso, o próximo apply reverte a lambda pra tag definida no terraform.tfvars
  lifecycle {
    ignore_changes = [image_uri]
  }
}