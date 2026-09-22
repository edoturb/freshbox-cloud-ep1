# 1. VPC Multi-AZ
resource "aws_vpc" "freshbox_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "FreshBox-VPC"
  }
}

# 2. Subredes Públicas (Capa 1 Web - ALB)
resource "aws_subnet" "public_1a" {
  vpc_id                  = aws_vpc.freshbox_vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = { Name = "Public-Subnet-1a" }
}

resource "aws_subnet" "public_1b" {
  vpc_id                  = aws_vpc.freshbox_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = { Name = "Public-Subnet-1b" }
}

# 3. Subredes Privadas App (Capa 2 Application)
resource "aws_subnet" "private_app_1a" {
  vpc_id            = aws_vpc.freshbox_vpc.id
  cidr_block        = "10.0.2.0/25"
  availability_zone = "us-east-1a"
  tags = { Name = "Private-App-Subnet-1a" }
}

resource "aws_subnet" "private_app_1b" {
  vpc_id            = aws_vpc.freshbox_vpc.id
  cidr_block        = "10.0.2.128/25"
  availability_zone = "us-east-1b"
  tags = { Name = "Private-App-Subnet-1b" }
}

# 4. Subredes Privadas Data (Capa 3 Data)
resource "aws_subnet" "private_data_1a" {
  vpc_id            = aws_vpc.freshbox_vpc.id
  cidr_block        = "10.0.3.0/25"
  availability_zone = "us-east-1a"
  tags = { Name = "Private-Data-Subnet-1a" }
}

resource "aws_subnet" "private_data_1b" {
  vpc_id            = aws_vpc.freshbox_vpc.id
  cidr_block        = "10.0.3.128/25"
  availability_zone = "us-east-1b"
  tags = { Name = "Private-Data-Subnet-1b" }
}

# 5. Gateways de Red
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.freshbox_vpc.id
  tags   = { Name = "FreshBox-IGW" }
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_1a.id
  tags          = { Name = "FreshBox-NAT-GW" }
}

# 6. Repositorios Amazon ECR
locals {
  services = [
    "freshbox-frontend",
    "freshbox-get-products",
    "freshbox-create-product",
    "freshbox-update-product",
    "freshbox-delete-product"
  ]
}

resource "aws_ecr_repository" "repos" {
  for_each             = toset(local.services)
  name                 = each.value
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}
