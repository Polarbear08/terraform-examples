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


locals {
  # Image list
  image_id = {
    centos7 = "ami-0affd4508a5d2481b"
  }
}

# VPC
resource "aws_vpc" "sample02-vpc" {
  cidr_block = "10.102.0.0/16"

  tags = {
    Group = "sample02"
    Name  = "sample02-vpc"
  }
}

# Subnet
resource "aws_subnet" "sample02-subnet01" {
  vpc_id                  = aws_vpc.sample02-vpc.id
  availability_zone       = "us-east-1a"
  cidr_block              = "10.102.1.0/24"
  map_public_ip_on_launch = "true"

  tags = {
    Group = "sample02"
    Name  = "sample02-subnet01"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "sample02-igw" {
  vpc_id = aws_vpc.sample02-vpc.id

  tags = {
    Group = "sample02"
    Name  = "sample02-igw"
  }
}

# Routing Table
resource "aws_route_table" "sample02-routetable01" {
  vpc_id = aws_vpc.sample02-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sample02-igw.id
  }

  tags = {
    Group = "sample02"
    Name  = "sample02-routetable01"
  }
}

# Routing Table Association
resource "aws_route_table_association" "sample02-association01" {
  subnet_id      = aws_subnet.sample02-subnet01.id
  route_table_id = aws_route_table.sample02-routetable01.id
}

# Security Group
resource "aws_security_group" "sample02-sg01" {
  description = "allow SSH and HTTP from specific IP address"
  vpc_id      = aws_vpc.sample02-vpc.id

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
    Group = "sample02"
    Name  = "sample02-sg01"
  }
}

# SSH key pair
resource "aws_key_pair" "sample02-keypair01" {
  key_name   = "sample-keypair01"
  public_key = var.public_key
}

# Assume Role for Spot Fleet Request
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["spotfleet.amazonaws.com"]
    }
  }
}

# Service Role for Spot Fleet Request
resource "aws_iam_role" "sample02-spotfleet-role" {
  name               = "sample02-spotfleet-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Attach a policy for tagging EC2
resource "aws_iam_policy_attachment" "policy-attach" {
  name       = "sample02-policy-attachment01"
  roles      = [aws_iam_role.sample02-spotfleet-role.id]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetTaggingRole"
}

# Spot Fleet Request
resource "aws_spot_fleet_request" "sample02-request01" {
  iam_fleet_role                      = aws_iam_role.sample02-spotfleet-role.arn
  target_capacity                     = 1
  terminate_instances_with_expiration = true
  wait_for_fulfillment                = true

  launch_specification {
    ami                         = local.image_id.centos7
    instance_type               = "t2.micro"
    key_name                    = aws_key_pair.sample02-keypair01.key_name
    vpc_security_group_ids      = [aws_security_group.sample02-sg01.id]
    subnet_id                   = aws_subnet.sample02-subnet01.id
    associate_public_ip_address = true

    tags = {
      Group = "sample02"
      Name  = "sample02-instance01"
    }
  }

  tags = {
    Group = "sample02"
    Name  = "sample02-request01"
  }
}

# data source of IP address of launced instance
data "aws_instance" "sample02-instances" {
  filter {
    name   = "tag:Group"
    values = ["sample02"]
  }

  depends_on = [
    aws_spot_fleet_request.sample02-request01
  ]
}
