terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
  }

  backend "s3" {}
}

provider "aws" {
  region = "us-east-1"
}

module "eks" {
  source           = "../../modules/eks"
  service          = "stock"
  account_id       = var.account_id
  eks_cluster_role = var.eks_cluster_role
  eks_node_role    = var.eks_node_role
  datadog_api_key  = var.datadog_api_key
  datadog_site     = var.datadog_site
}

data "aws_eks_cluster_auth" "main" {
  name = module.eks.cluster_name
}

provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}
