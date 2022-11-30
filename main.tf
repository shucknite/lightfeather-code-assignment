resource "aws_vpc" "lightfeather_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    name = "lightfeather-vpc",
  }

}

resource "aws_subnet" "lightfeather_subnet" {
  vpc_id                  = aws_vpc.lightfeather_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.lightfeather_vpc.cidr_block, 8, 1) 
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zones

  tags = {
    Name = "lightfeather-subnet",
  }

}

resource "aws_subnet" "lightfeather_subnet2" {
  vpc_id                  = aws_vpc.lightfeather_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.lightfeather_vpc.cidr_block, 8, 2) 
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zones

  tags = {
    Name = "lightfeather-subnet2",
  }

}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.lightfeather_vpc.id

  tags = {
    Name = "lightfeather-igw"
  }

}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.lightfeather_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "lightfeather-rt"
  }

}

resource "aws_route_table_association" "subnet_route" {
  subnet_id      = aws_subnet.lightfeather_subnet.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "subnet_route2" {
  subnet_id      = aws_subnet.lightfeather_subnet2.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "sg" {
  name   = "lightfeather-ecs-sg"
  vpc_id = aws_vpc.lightfeather_vpc.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress  {
    from_port = 110
    to_port = 110
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress  {
    from_port = 25
    to_port = 25
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress  {
    from_port = 587
    to_port = 587
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress  {
    from_port = 465
    to_port = 465
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress  {
    from_port = 53
    to_port = 53
    protocol = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

   tags = {
    Name = "lightfeather-sg"
  }

}

resource "aws_ecs_cluster" "lightfeather_cluster" {
  name = "lightfeather-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "lightfeather-cluster"
  }

}

resource "aws_ecs_task_definition" "lightfeather_task" {
  family = "service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE", "EC2"]
  cpu                      = 512
  memory                   = 2048
  container_definitions = jsonencode([
    {
      name      = "backend",
      image     = "shucknite/backend:latest"
      cpu       = 10
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
    },
    {
      name      = "fronend"
      image     = "shucknite/frontend:latest"
      cpu       = 10
      memory    = 256
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
    }
  ])

   tags = {
    Name = "lightfeather-tasks",
  }

}

resource "aws_ecs_service" "service" {
  name             = "lightfeather-service"
  cluster          = aws_ecs_cluster.lightfeather_cluster.id
  task_definition  = aws_ecs_task_definition.lightfeather_task.id
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "LATEST"

  network_configuration {
    assign_public_ip = true
    security_groups  = [aws_security_group.sg.id]
    subnets          = [aws_subnet.lightfeather_subnet.id]
  }
  lifecycle {
    ignore_changes = [task_definition]
  }

  tags = {
    Name = "lightfeather-service",
  }

}