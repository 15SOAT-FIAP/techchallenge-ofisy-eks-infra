output "vpc_id" {
  description = "ID da VPC criada"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs das subnets públicas"
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas"
  value       = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

output "eks_cluster_name" {
  description = "Nome do cluster EKS"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "Endpoint do API Server do EKS"
  value       = aws_eks_cluster.main.endpoint
}

output "eks_security_group_id" {
  description = "ID do Security Group do EKS"
  value       = aws_security_group.eks.id
}

output "ecr_repository_url" {
  description = "URL do repositório ECR"
  value       = aws_ecr_repository.main.repository_url
}

output "ecr_auth_repository_url" {
  description = "URL do repositório ECR da Lambda de autenticação"
  value       = aws_ecr_repository.auth.repository_url
}
