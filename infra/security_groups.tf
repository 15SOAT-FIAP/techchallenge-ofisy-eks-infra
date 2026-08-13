########################################
# SECURITY GROUP - EKS
########################################

resource "aws_security_group" "eks" {
  name        = "${local.project_name}-eks-sg"
  description = "Security Group para o cluster EKS"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.project_name}-eks-sg"
  }
}

resource "aws_security_group_rule" "eks_self_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.eks.id
}

resource "aws_security_group_rule" "eks_ssh_ingress" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks.id
}

resource "aws_security_group_rule" "eks_http_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks.id
}

resource "aws_security_group_rule" "eks_https_ingress" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks.id
}

resource "aws_security_group_rule" "eks_app_ingress" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks.id
}

resource "aws_security_group_rule" "eks_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks.id
}

########################################
# SECURITY GROUP - LAMBDA CUSTOMERS AUTH
########################################

resource "aws_security_group" "lambda_auth" {
  name        = "${local.project_name}-lambda-auth-sg"
  description = "Security Group para a Lambda de autenticacao de clientes"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.project_name}-lambda-auth-sg"
  }
}

resource "aws_security_group_rule" "lambda_auth_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lambda_auth.id
}
