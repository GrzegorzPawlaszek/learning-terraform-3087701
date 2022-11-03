data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["bitnami-tomcat-*-x86_64-hvm-ebs-nami"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["979382823631"] # Bitnami
}

# defaultowa vpc stworzona przez AWS'a
data "aws_vpc" "default" {
  default = true
}

resource "aws_instance" "blog" {
  ami           = data.aws_ami.app_ami.id
  # pobranie typu instancji z pliku variables.tf
  instance_type = var.instance_type
  
  vpc_security_group_ids = [aws_security_group.blog.id]

  tags = {
    Name = "HelloWorld"
  }
}

# definicja secutiry_group, która będzie działać jako FireWall
resource "aws_security_group" "blog" {
  name        = "blog"
  description = "Allow http and https in. Allow everything out."
  
  # odwołanie się do defaultowej VPC
  vpc_id = data.aws_vpc.default.id
}

# reguła na ruch http wchodzący
resource "aws_security_group_rule" "blog_http_in" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  # dozwolony ruch z dowolnego adresu IP
  cird_blocks = ["0.0.0.0/0"]
  
  security_group_id = aws_security_group.blog.id
}

# reguła na ruch https wchodzący
resource "aws_security_group_rule" "blog_https_in" {
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cird_blocks = ["0.0.0.0/0"]
  
  security_group_id = aws_security_group.blog.id
}

# reguła na ruch wychodzący
resource "aws_security_group_rule" "blog_out" {
  type        = "egress"
  from_port   = 80
  to_port     = 80
  # dozwolony ruch po wszystkich protokołach
  protocol    = "-1"
  # dozwolony ruch na dowolny adres IP
  cird_blocks = ["0.0.0.0/0"]
  
  security_group_id = aws_security_group.blog.id
}


