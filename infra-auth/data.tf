########################################
# DATA SOURCES - NETWORK/SECURITY
########################################

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

data "aws_security_group" "lambda_auth" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  filter {
    name   = "tag:Name"
    values = ["${local.project_name}-lambda-auth-sg"]
  }
}

########################################
# DATA SOURCES - ECR/RDS
########################################

data "aws_ecr_repository" "auth" {
  name = "${local.project_name}-auth"
}

data "aws_ecr_repository" "auth_authorizer" {
  name = "${local.project_name}-auth-authorizer"
}

# Instância RDS provisionada pelo repositório techchallenge-ofisy-rds-infra
data "aws_db_instance" "main" {
  db_instance_identifier = "${local.project_name}-postgres-db"
}

# Security Group do RDS, criado no repositorio techchallenge-ofisy-rds-infra.
# So estamos "lendo" - a regra que libera a lambda de auth para ele fica em
# rds_access.tf deste modulo (nao mexe no repo do RDS).
data "aws_security_group" "rds" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  filter {
    name   = "tag:Name"
    values = ["${local.project_name}-rds-sg"]
  }
}