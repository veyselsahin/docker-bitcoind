variable "access_key" {
  type        = string
  description = ""
}
variable "secret_key" {
  type        = string
  description = ""
}
provider "aws" {
  region     = "us-west-2"
  access_key = var.access_key
  secret_key = var.secret_key
}
variable "IMAGE" {
  type        = string
  description = ""
}
resource "aws_vpc" "foo" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "ECS-EFS-VPC"
  }
}

resource "aws_subnet" "alpha" {
  vpc_id            =  aws_vpc.foo.id
  availability_zone = "us-west-2a"
  cidr_block        = "10.0.1.0/24"

  tags = {
    Name = "ECS-EFS-SUBNET"
  }
}
resource "aws_efs_file_system" "efs" {
  tags = {
    Name = "ECS-EFS-FS"
  }
}

resource "aws_efs_mount_target" "mount" {
  file_system_id = aws_efs_file_system.efs.id
  subnet_id      = aws_subnet.alpha.id
}

resource "aws_ecs_cluster" "ecs-bitcoin" {
  name = "efs-example"
}

resource "aws_ecs_service" "bar" {
  name            = "efs-example-service"
  cluster         = aws_ecs_cluster.ecs-bitcoin.id
  task_definition = aws_ecs_task_definition.efs-task.arn
  desired_count   = 2
  launch_type     = "EC2"

  network_configuration {
    subnets = [aws_subnet.alpha.id]
  }
}

resource "aws_ecs_task_definition" "efs-task" {
  family        = "efs-example-task"
  network_mode = "awsvpc"

  container_definitions = <<DEFINITION
[
  {
      "memory": 128,
      "portMappings": [
          {
              "hostPort": 80,
              "containerPort": 80,
              "protocol": "tcp"
          }
      ],
      "essential": true,
      "mountPoints": [
          {
              "containerPath": "/bitcoin/.bitcoin",
              "sourceVolume": "efs-data"
          }
      ],
      "name": "docker-bitcoind",
      "image": "${var.IMAGE}"
  }
]
DEFINITION

  volume {
    name      = "efs-data"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.efs.id
      root_directory = "/bitcoin/.bitcoin"
    }
  }
}