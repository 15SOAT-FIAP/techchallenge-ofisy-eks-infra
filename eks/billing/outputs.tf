output "eks_cluster_name" {
  description = "Nome do cluster EKS"
  value       = module.eks.cluster_name
}

output "ecr_repository_url" {
  description = "URL do repositório ECR"
  value       = module.eks.ecr_repository_url
}
