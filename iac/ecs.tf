
variable "ambientes" {
  description = "Lista de entornos"
  type        = map(any)
  default = {
    dev  = { name = "dev" }
    test = { name = "test" }
    prod = { name = "prod" }
  }
}

# Crear Clusters ECS
resource "aws_ecs_cluster" "ecs_cluster" {
  for_each = var.ambientes

  name = "${each.value.name}-ecs-cluster"

  tags = {
    Name = "${each.value.name}-ecs-cluster"
  }
}

