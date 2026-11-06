########################################
# EKS CLUSTER
########################################

resource "aws_eks_cluster" "main" {
  name     = "${local.name_prefix}-cluster"
  role_arn = "arn:aws:iam::${var.account_id}:role/${var.eks_cluster_role}"

  vpc_config {
    subnet_ids         = concat(data.aws_subnets.public.ids, data.aws_subnets.private.ids)
    security_group_ids = [data.aws_security_group.eks.id]

    endpoint_public_access  = true
    endpoint_private_access = true
  }

  tags = {
    Name = "${local.name_prefix}-cluster"
  }
}

########################################
# EKS NODE GROUP
########################################

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${local.name_prefix}-node-group"
  node_role_arn   = "arn:aws:iam::${var.account_id}:role/${var.eks_node_role}"
  subnet_ids      = data.aws_subnets.private.ids

  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    role = "general"
  }

  tags = {
    Name = "${local.name_prefix}-node-group"
  }
}
