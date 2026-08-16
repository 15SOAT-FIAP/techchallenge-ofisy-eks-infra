variable "aws_region" {
  description = "Região da AWS onde a infraestrutura será criada"
  type        = string
  default     = "us-east-1"
}

variable "account_id" {
  description = "ID da conta AWS"
  type        = string
}

variable "role_name" {
  description = "Nome da Role de Execução da Lambda (ex: LabRole para AWS Academy)"
  type        = string
  default     = "LabRole"
}

variable "image_tag" {
  description = "Tag da imagem no ECR para deploy (SHA do commit publicado pelo CD do repositório de auth)"
  type        = string
}

variable "authorizer_image_tag" {
  description = "Tag da imagem no ECR do authorizer para deploy (SHA do commit publicado pelo CD do repositório de auth)"
  type        = string
}

variable "db_password" {
  description = "Senha do usuário administrativo do banco de dados PostgreSQL"
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "Segredo utilizado para assinar os tokens JWT"
  type        = string
  sensitive   = true
}

variable "jwt_expiration" {
  description = "Tempo de expiração dos tokens JWT"
  type        = string
  default     = "1h"
}