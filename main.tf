provider "aws" {
  region = var.aws_region
  profile = var.aws_profile
}

# create an instance
resource "aws_instance" "instance_main" {
  ami           = "ami-068c0051b15cdb816"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.sub_main.id

  vpc_security_group_ids = [
    aws_security_group.allow_tls.id
  ]

  tags = {
    Name = "HelloWorld"
  }
}


# create a VPC
resource "aws_vpc" "VPC_main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "VPC_tags"
  }
}

resource "aws_subnet" "sub_main" {
  vpc_id                  = aws_vpc.VPC_main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "SUbnet_tags"
  }
}

# create a route table
resource "aws_route_table" "RT_main" {
  vpc_id = aws_vpc.VPC_main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.int_gt.id
  }

  tags = {
    Name = "main-rt"
  }
}


# Associate subnet to Route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.sub_main.id
  route_table_id = aws_route_table.RT_main.id
}

# Create an Internet gateway
resource "aws_internet_gateway" "int_gt" {
  vpc_id = aws_vpc.VPC_main.id

  tags = {
    Name = "gateway_tags"
  }
}

# create a security group
resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS, SSH, HTTP inbound and all outbound traffic"
  vpc_id      = aws_vpc.VPC_main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.VPC_main.cidr_block]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.VPC_main.cidr_block]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.VPC_main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}