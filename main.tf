terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  region     = "us-east-2"
}


# -------------------------
# VPC
# -------------------------
resource "aws_vpc" "prod" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "production-vpc"
  }
}

# -------------------------
# Public Subnets
# -------------------------
resource "aws_subnet" "public_subnets" {
  vpc_id            = aws_vpc.prod.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-2a"

  tags = {
    Name = "Public Subnet 1"
  }
}

# -------------------------
# Private Subnets
# -------------------------
resource "aws_subnet" "private_subnets" {
  vpc_id            = aws_vpc.prod.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "Private Subnet 1"
  }
}

# -------------------------
# Internet Gateway
# -------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.prod.id

  tags = {
    Name = "prod-igw"
  }
}

# -------------------------
# Public Route Table
# -------------------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.prod.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Ned-Project-VPC-Public-Route-Table"
  }
}

resource "aws_route_table_association" "public_subnet_asso" {
  subnet_id      = aws_subnet.public_subnets.id
  route_table_id = aws_route_table.public_rt.id
}


# -------------------------
# Security Group (for Public Subnets only)
# -------------------------
resource "aws_security_group" "public_sg" {
  name        = "public-sg"
  description = "Allow SSH (22) and HTTPS (443) from anywhere; all outbound"
  vpc_id      = aws_vpc.prod.id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "PublicSecurityGroup"
  }
}


# Public NIC
resource "aws_network_interface" "public_nic" {
  subnet_id       = aws_subnet.public_subnets.id
  private_ips     = ["10.0.1.5"]                               
  security_groups = [aws_security_group.public_sg.id]

  tags = {
    Name = "ENI-Public"
  }
}

# Private NIC
resource "aws_network_interface" "private_nic" {
  subnet_id       = aws_subnet.private_subnets.id
  private_ips     = ["10.0.10.5"]
  
  tags = {
    Name = "ENI-Private"
  }
}


# -------------------------
# EC2 Instance (in Public Subnets)
# -------------------------
resource "aws_instance" "my_web_server" {
  ami               = "ami-05e41d4619abf276a"
  instance_type     = "t3.small"
  availability_zone = "us-east-2a"
  key_name          = "ned_ubuntu"

  # Define the network interfaces to attach directly to the instance
  network_interface {
    network_interface_id = aws_network_interface.public_nic.id
    device_index         = 0
  }

  

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install nginx -y
              sudo systemctl start nginx
              sudo systemctl enable nginx
              echo "<h1>This is Ned's web server</h1>" | sudo tee /var/www/html/index.html
              EOF
  tags = {
    Name = "Test-Web-Server"
  }
}

# -------------------------
# Elastic IP and NAT Gateway
# -------------------------
resource "aws_eip" "eip" {
  domain            = "vpc"
  network_interface = aws_network_interface.public_nic.id
  tags = {
    Name = "EIP"
  }
  depends_on = [aws_internet_gateway.igw]
}
