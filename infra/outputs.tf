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

output "eks_security_group_id" {
  description = "ID do Security Group do EKS"
  value       = aws_security_group.eks.id
}

output "ecr_auth_repository_url" {
  description = "URL do repositório ECR da Lambda de autenticação"
  value       = aws_ecr_repository.auth.repository_url
}
