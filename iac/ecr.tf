resource "aws_ecr_repository" "ecr_repos" {
  for_each = {
    orders   = "orders-service-ecr-repo"
    products = "products-service-ecr-repo"
    shipping = "shipping-service-ecr-repo"
    payments = "payments-service-ecr-repo"
  }

  name                 = each.value
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = false
  }

  tags = {
    Name        = each.value
    Environment = each.key
  }
}

resource "aws_ecr_lifecycle_policy" "ecr_lifecycle_policies" {
  for_each = aws_ecr_repository.ecr_repos

  repository = each.value.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images",
        selection = {
          tagStatus   = "any",
          countType   = "imageCountMoreThan",
          countNumber = 30,
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}
