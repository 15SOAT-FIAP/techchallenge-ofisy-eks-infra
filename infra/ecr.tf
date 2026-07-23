########################################
# ECR REPOSITORY
########################################

resource "aws_ecr_repository" "main" {
  name                 = "ofisy-ecr"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${local.project_name}-ecr"
  }
}
