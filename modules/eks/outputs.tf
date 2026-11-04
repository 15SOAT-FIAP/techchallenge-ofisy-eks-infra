output "cluster_name" {
  description = "Nome do cluster EKS"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint do API Server do EKS"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_ca" {
  description = "Certificado da CA do cluster (base64)"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "ecr_repository_url" {
  description = "URL do repositório ECR do microsserviço"
  value       = aws_ecr_repository.main.repository_url
}
