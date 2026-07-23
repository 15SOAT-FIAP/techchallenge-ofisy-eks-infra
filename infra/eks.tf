########################################
# EKS CLUSTER
########################################

resource "aws_eks_cluster" "main" {
  name     = "${local.project_name}-cluster"
  role_arn = "arn:aws:iam::${var.account_id}:role/${var.eks_cluster_role}"

  vpc_config {
    subnet_ids         = [aws_subnet.public_a.id, aws_subnet.public_b.id, aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.eks.id]

    endpoint_public_access  = true
    endpoint_private_access = true
  }

  tags = {
    Name = "${local.project_name}-cluster"
  }

  depends_on = [
    aws_internet_gateway.main
  ]
}

########################################
# EKS NODE GROUP
########################################

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${local.project_name}-node-group"
  node_role_arn   = "arn:aws:iam::${var.account_id}:role/${var.eks_node_role}"
  subnet_ids      = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    role = "general"
  }

  tags = {
    Name = "${local.project_name}-node-group"
  }

  depends_on = [
    aws_eks_cluster.main
  ]
}
