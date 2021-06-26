# Terraformのprovider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# AWS provider
provider "aws" {
  region                  = "us-east-1"
  shared_credentials_file = "./.aws/credentials"
  profile                 = "terraform-tutorial"
}

# Image list
locals {
  image_id = {
    centos7 = "ami-0affd4508a5d2481b"
  }
}

# VPC
resource "aws_vpc" "sample01-vpc" {
  cidr_block = "10.101.0.0/16"

  tags = {
    Group = "sample01"
    Name  = "sample01-vpc"
  }
}

# Subnet
resource "aws_subnet" "sample01-subnet01" {
  vpc_id                  = aws_vpc.sample01-vpc.id
  availability_zone       = "us-east-1a"
  cidr_block              = "10.101.1.0/24"
  map_public_ip_on_launch = "true"

  tags = {
    Group = "sample01"
    Name  = "sample01-subnet01"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "sample01-igw" {
  vpc_id = aws_vpc.sample01-vpc.id

  tags = {
    Group = "sample01"
    Name  = "sample01-igw"
  }
}

# Routing Table
resource "aws_route_table" "sample01-routetable01" {
  vpc_id = aws_vpc.sample01-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sample01-igw.id
  }

  tags = {
    Group = "sample01"
    Name  = "sample01-routetable01"
  }
}

# Routing Table Association
resource "aws_route_table_association" "sample01-association01" {
  subnet_id      = aws_subnet.sample01-subnet01.id
  route_table_id = aws_route_table.sample01-routetable01.id
}

# Security Group
resource "aws_security_group" "sample01-sg01" {
  description = "allow SSH and HTTP from specific IP address"
  vpc_id      = aws_vpc.sample01-vpc.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.local_ips
  }

  ingress {
    description = "HTTP from my IP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.local_ips
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Group = "sample01"
    Name  = "sample01-sg01"
  }
}

# SSH key pair
resource "aws_key_pair" "sample01-keypair01" {
  key_name   = "sample-keypair01"
  public_key = var.public_key
}

# EC2 instance
resource "aws_instance" "sample01-instance01" {
  ami                         = local.image_id.centos7
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.sample01-keypair01.key_name
  vpc_security_group_ids      = [aws_security_group.sample01-sg01.id]
  subnet_id                   = aws_subnet.sample01-subnet01.id
  associate_public_ip_address = true

  tags = {
    Group = "sample01"
    Name  = "sample01-instance01"
  }
  volume_tags = {
    Group = "sample01"
    Name  = "sample01-volume01"
  }
}
