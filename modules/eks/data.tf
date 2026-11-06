########################################
# DATA SOURCES - NETWORK/SECURITY
#
# Rede e Security Group compartilhados, criados pela raiz infra/
########################################

locals {
  project_name = "ofisy"
  name_prefix  = "ms-${local.project_name}-${var.service}"
}

data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["${local.project_name}-vpc"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  filter {
    name   = "tag:Name"
    values = ["${local.project_name}-public-subnet-*"]
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
