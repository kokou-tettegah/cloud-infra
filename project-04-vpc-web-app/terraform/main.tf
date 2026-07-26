terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "project-04-vpc"
    Project     = "project-04-vpc-web-app"
    Environment = "sandbox"
    Owner       = "kokou"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "project-04-public-subnet"
    Project     = "project-04-vpc-web-app"
    Environment = "sandbox"
    Owner       = "kokou"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name        = "project-04-private-subnet"
    Project     = "project-04-vpc-web-app"
    Environment = "sandbox"
    Owner       = "kokou"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "project-04-igw"
    Project     = "project-04-vpc-web-app"
    Environment = "sandbox"
    Owner       = "kokou"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "project-04-public-rt"
    Project     = "project-04-vpc-web-app"
    Environment = "sandbox"
    Owner       = "kokou"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "project-04-nat-eip"
    Project     = "project-04-vpc-web-app"
    Environment = "sandbox"
    Owner       = "kokou"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name        = "project-04-nat-gw"
    Project     = "project-04-vpc-web-app"
    Environment = "sandbox"
    Owner       = "kokou"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name        = "project-04-private-rt"
    Project     = "project-04-vpc-web-app"
    Environment = "sandbox"
    Owner       = "kokou"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "public" {
  name        = "project-04-public-sg"
  description = "Allow HTTP from anywhere, SSH from admin IP only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from admin IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "project-04-public-sg"
    Project     = "project-04-vpc-web-app"
    Environment = "sandbox"
    Owner       = "kokou"
  }
}

resource "aws_security_group" "private" {
  name        = "project-04-private-sg"
  description = "Allow SSH only from the public/bastion security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "SSH from bastion only"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "project-04-private-sg"
    Project     = "project-04-vpc-web-app"
    Environment = "sandbox"
    Owner       = "kokou"
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.public.id]
  key_name                    = "project-04-key"
  associate_public_ip_address = true

  user_data = <<-USERDATA
              #!/bin/bash
              dnf install -y httpd
              systemctl enable httpd
              systemctl start httpd
              echo "<h1>Project 4 - Public Web/Bastion Instance</h1>" > /var/www/html/index.html
              USERDATA

  tags = {
    Name        = "project-04-web-bastion"
    Project     = "project-04-vpc-web-app"
    Environment = "sandbox"
    Owner       = "kokou"
  }
}

resource "aws_instance" "private" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.private.id]
  key_name               = "project-04-key"

  tags = {
    Name        = "project-04-private-instance"
    Project     = "project-04-vpc-web-app"
    Environment = "sandbox"
    Owner       = "kokou"
  }
}
