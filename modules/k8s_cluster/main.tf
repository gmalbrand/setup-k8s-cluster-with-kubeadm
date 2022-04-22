terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.8.0"
    }
  }
}


resource "random_id" "id" {
  byte_length = 8
}

locals {
  env_name         = "k8s-cluster-${random_id.id.hex}"
  controller_names = [for i in range(var.controller_number) : "controller-${i}"]
  worker_names     = [for i in range(var.worker_number) : "worker-${i}"]
}

resource "local_file" "inventory" {
  content = templatefile("${path.module}/inventory.tftpl", {
    environment_name = local.env_name,
    controllers = [
      for instance in aws_instance.controllers :
      {
        "name"       = instance.tags.Name,
        "public_ip"  = instance.public_ip,
        "private_ip" = instance.private_ip
      }
    ],
    workers = [
      for instance in aws_instance.workers :
      {
        "name"       = instance.tags.Name,
        "public_ip"  = instance.public_ip,
        "private_ip" = instance.private_ip
      }

    ]
  })
  filename        = format("%s/%s", abspath(path.root), "inventory.ini")
  file_permission = "0600"
}


data "aws_ami" "debian" {
  most_recent = true
  filter {
    name   = "name"
    values = ["debian-10-amd64-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["136693071363"] # Canonical
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_instance" "workers" {
  count                       = var.worker_number
  ami                         = data.aws_ami.debian.id
  instance_type               = "t2.medium"
  key_name                    = var.default_key_pair
  vpc_security_group_ids      = [var.security_group_id]
  availability_zone           = data.aws_availability_zones.available.names[0]
  associate_public_ip_address = true

  tags = {
    Name        = "${local.worker_names[count.index]}"
    Environment = "${local.env_name}"
  }
}

resource "aws_instance" "controllers" {
  count                       = var.controller_number
  ami                         = data.aws_ami.debian.id
  instance_type               = "t2.medium"
  key_name                    = var.default_key_pair
  vpc_security_group_ids      = [var.security_group_id]
  availability_zone           = data.aws_availability_zones.available.names[0]
  associate_public_ip_address = true

  tags = {
    Name        = "${local.controller_names[count.index]}"
    Environment = "${local.env_name}"
  }
}
