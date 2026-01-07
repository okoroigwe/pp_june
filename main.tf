provider "aws" {
  region = var.aws_region
  profile = var.aws_profile
}
 
 data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


# create an instance
resource "aws_instance" "firstinstance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.sub_main.id

  vpc_security_group_ids = [
    aws_security_group.allow_tls.id
  ]
  key_name = "olisa_keypair"

user_data = file("install_jenkins.sh")


  tags = {
    Name = "HelloWorld"
  }
}

# create an instance for tomcat
resource "aws_instance" "secondinstance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.sub_main.id

  vpc_security_group_ids = [
    aws_security_group.allow_tls.id
  ]
  key_name = "olisa_keypair"

user_data = file("install_tomcat.sh")


  tags = {
    Name = "Tomcat_Server"
  }
}

# print the url of the jenkins server
output "jenkins_url" {
  value = "http://${aws_instance.firstinstance.public_ip}:8080"
  description = "jenkins server which is firsinstance from resource block"
}

# print the url of the tomcat server
output "tomcat_url" {
  value = "http://${aws_instance.secondinstance.public_ip}:8080"
  description = "Tomcat server is secondinstance"
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
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Jenkins
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Tomcat
  ingress {
    from_port   = 8081
    to_port     = 8081
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
    Name = "allow_tls"
  }
}
