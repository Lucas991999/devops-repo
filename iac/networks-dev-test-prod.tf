variable "environments" {
  description = "Definición de ambientes"
  type = map(object({
    cidr_block        = string
    subnet_cidr       = string
    availability_zone = string
  }))
  default = {
    dev = {
      cidr_block        = "10.1.0.0/16"
      subnet_cidr       = "10.1.1.0/24"
      availability_zone = "us-east-1a"
    },
    test = {
      cidr_block        = "10.2.0.0/16"
      subnet_cidr       = "10.2.1.0/24"
      availability_zone = "us-east-1b"
    },
    prod = {
      cidr_block        = "10.3.0.0/16"
      subnet_cidr       = "10.3.1.0/24"
      availability_zone = "us-east-1c"
    }
  }
}


# Resource: Crear VPC
resource "aws_vpc" "vpc-ecs" {
  for_each = var.environments

  cidr_block = each.value.cidr_block

  tags = {
    "Name" = "vpc-ecs-${each.key}"
  }
}

# Resource: Crear Subnets
resource "aws_subnet" "vpc-ecs-public-subnet" {
  for_each = var.environments

  vpc_id                  = aws_vpc.vpc-ecs[each.key].id
  cidr_block              = each.value.subnet_cidr
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = true

  tags = {
    "Name" = "subnet-ecs-${each.key}"
  }
}

# Resource: Crear Internet Gateway
resource "aws_internet_gateway" "vpc-ecs-igw" {
  for_each = var.environments

  vpc_id = aws_vpc.vpc-ecs[each.key].id
}

# Resource: Crear Route Table
resource "aws_route_table" "vpc-ecs-public-route-table" {
  for_each = var.environments

  vpc_id = aws_vpc.vpc-ecs[each.key].id
}

# Resource: Crear Route en Route Table para acceso a internet
resource "aws_route" "vpc-ecs-public-route" {
  for_each = var.environments

  route_table_id         = aws_route_table.vpc-ecs-public-route-table[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.vpc-ecs-igw[each.key].id
}

# Resource: Asociar Route Table con la Subnet
resource "aws_route_table_association" "vpc-ecs-public-route-table-associate" {
  for_each = var.environments

  route_table_id = aws_route_table.vpc-ecs-public-route-table[each.key].id
  subnet_id      = aws_subnet.vpc-ecs-public-subnet[each.key].id
}

# Resource: Crear Security Group Load Balancers
resource "aws_security_group" "ecs-load-balancers-sg" {
  for_each = var.environments

  name        = "${each.key}-vpc-load-balancers-sg"
  vpc_id      = aws_vpc.vpc-ecs[each.key].id
  description = "${each.key} Load Balancers Security Group"

  ingress {
    description = "Allow Port 80 for load balancers"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all ip and ports outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "loadbalancers-${each.key}-security-group"
  }
  depends_on = [aws_vpc.vpc-ecs]
}

# Resource: Crear Security Group para servicios ECS
resource "aws_security_group" "ecs-contenedores-sg" {
  for_each = var.environments

  name        = "${each.key}-contenedores-sg"
  vpc_id      = aws_vpc.vpc-ecs[each.key].id
  description = "${each.key} Contenedores Security Group"

  ingress {
    description     = "Allow all traffic from load balancers"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.ecs-load-balancers-sg[each.key].id]
  }

  egress {
    description = "Allow all ip and ports outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "contenedores-${each.key}-security-group"
  }
  depends_on = [
    aws_vpc.vpc-ecs,
    aws_security_group.ecs-load-balancers-sg
  ]
}