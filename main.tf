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
  
  # podpięcie security_group z modułu. Output dla id securoty group'y jest podany w zakłądce Outputs na stronie registry.terraform.io dla tego modułu
  vpc_security_group_ids = [module.blog_sg.security_group_id]

  tags = {
    Name = "HelloWorld"
  }
}
  
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "dev"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}  

# security group zdefiniowana za pomocą predefiniowanego modułu pobranego z registry.terraform.io
module "blog_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.16.0"
  name    = "blog_new"
  
  vpc_id = module.vpc.vpc_id
  
  # definicja reguł za pomocą predefiniowanych nazw: https://github.com/terraform-aws-modules/terraform-aws-security-group/blob/master/rules.tf
  # to w jaki sposób i co możemy definiować dla modułu jest opisane w sekcji Inputs na stronie registry.terraform.io dla tego modułu
  ingress_rules       = ["http-80-tcp","https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  
  egress_rules        = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}


