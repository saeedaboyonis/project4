provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}
resource "aws_vpc" "main" {
  cidr_block       = "10.88.0.0/16"
  instance_tenancy = "default"
  
  tags = {
    Name = "aws_vpc_tf"
  }
}
resource "aws_subnet" "aws_subnet_public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.88.1.0/24"
  
  tags = {
    Name = "aws_subnet_public_tf"
  }
}
resource "aws_subnet" "aws_subnet_private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.88.2.0/24"
  
  tags = {
    Name = "aws_subnet_private_tf"
  }
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "gw_tf"
  }
}

resource "aws_eip" "lb" {
  vpc      = true
}

resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.lb.id
  subnet_id     = aws_subnet.aws_subnet_public.id

  tags = {
    Name = "gw NAT"
  }
}

resource "aws_route_table" "rt_public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "rt_public_tf"
  }
}
resource "aws_route_table_association" "a" {
subnet_id = aws_subnet.aws_subnet_public.id
 route_table_id = aws_route_table.rt_public.id
}

  resource "aws_route_table" "rt_private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.gw.id
  }

  tags = {
    Name = "rt_private_tf"
  }
} 
resource "aws_route_table_association" "b" {
 subnet_id = aws_subnet.aws_subnet_private.id
 route_table_id = aws_route_table.rt_private.id
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_security_group" "allow_web" {
  name = "allow_web_traffic"
  description = "Allow inbound web traffic"
  vpc_id = aws_vpc.main.id

  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "All networks allowed"
    from_port = 80
    to_port = 80
    protocol = "tcp"
  }
  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "HTTP"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
  }

  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
  }

  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
  }
  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "All networks allowed"
    from_port = 0
    to_port = 0
    protocol = "-1"
  }

  egress  {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "All networks allowed"
    from_port = 0
    to_port = 0
    protocol = "-1"
  }

  tags = {
    "Name" = "main-sg"
  }

}

resource "aws_network_interface" "web1" {
  subnet_id       = aws_subnet.aws_subnet_public.id
  private_ips     = ["10.88.1.172"]
  security_groups = [aws_security_group.allow_web.id]
  
}
resource "aws_eip" "two" {
  vpc                       = true
  network_interface         = aws_network_interface.web1.id
  associate_with_private_ip = "10.88.1.172"
}
resource "aws_network_interface" "web2" {
  subnet_id       = aws_subnet.aws_subnet_private.id
  private_ips     = ["10.88.2.141"]
  security_groups = [aws_security_group.allow_web.id]
  
}

resource "aws_instance" "web1" {
  ami           = var.image_id
  instance_type = "t2.micro"
  key_name= var.key_name

 network_interface {
    network_interface_id = aws_network_interface.web1.id
    device_index         = 0
  }
  user_data = <<-EOF
		#! /bin/bash
    sleep 30
    sudo apt update -y
    sudo apt install -y docker.io
    docker pull wordpress
    docker run -itd -e WORDPRESS_DB_HOST=10.88.2.141 -e WORDPRESS_DB_USER=wordpress -e WORDPRESS_DB_PASSWORD=wordpress -e WORDPRESS_DB_NAME=wordpress -p 80:80 wordpress
  EOF

  tags = {
    Name = "wordpress_tf"
  }
}

resource "aws_instance" "web2" {
  ami           = var.image_id
  instance_type = "t2.micro"
  key_name= var.key_name
  user_data = <<-EOF
		#! /bin/bash
    sudo apt update -y
    sudo apt install -y docker.io
    docker pull mysql
    docker run -itd -e MYSQL_ROOT_PASSWORD=wordpress -e MYSQL_DATABASE=wordpress -e MYSQL_USER=wordpress -e MYSQL_PASSWORD=wordpress -p 3306:3306 mysql 
  EOF
  network_interface {
    network_interface_id = aws_network_interface.web2.id
    device_index         = 0
  }

  tags = {
    Name = "sql_tf"
  }
}

