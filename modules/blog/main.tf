data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami_filter.name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = [var.ami_filter.owner]
}

resource "aws_instance" "blog" {
  ami           = data.aws_ami.app_ami.id
  # pobranie typu instancji z pliku variables.tf
  instance_type = var.instance_type
  
  # podpięcie security_group z modułu. Output dla id securoty group'y jest podany w zakłądce Outputs na stronie registry.terraform.io dla tego modułu
  vpc_security_group_ids = [module.blog_sg.security_group_id]
  subnet_id              = module.blog_vpc.public_subnets[0]

  tags = {
    Name = "HelloWorld"
  }
}
  
module "blog_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.environment.name
  cidr = "${var.environment.network_prefix}.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  public_subnets  = ["${var.environment.network_prefix}.101.0/24", "${var.environment.network_prefix}.102.0/24", "${var.environment.network_prefix}.103.0/24"]

  enable_nat_gateway = true

  tags = {
    Terraform = "true"
    Environment = var.environment.name
  }
}

# security group zdefiniowana za pomocą predefiniowanego modułu pobranego z registry.terraform.io
module "blog_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.16.0"
  
  name   = "${var.environment.name}-blog"
  vpc_id = module.blog_vpc.vpc_id
  
  # definicja reguł za pomocą predefiniowanych nazw: https://github.com/terraform-aws-modules/terraform-aws-security-group/blob/master/rules.tf
  # to w jaki sposób i co możemy definiować dla modułu jest opisane w sekcji Inputs na stronie registry.terraform.io dla tego modułu
  ingress_rules       = ["http-80-tcp","https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  
  egress_rules        = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}

module "blog_alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"

  name = "${var.environment.name}-blog-alb"

  load_balancer_type = "application"

  vpc_id             = module.blog_vpc.vpc_id
  subnets            = module.blog_vpc.public_subnets
  security_groups    = [module.blog_sg.security_group_id]

  target_groups = [
    {
      name_prefix      = "${var.environment.name}-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      targets = {
        my_target = {
          target_id = aws_instance.blog.id
          port = 80
        }
      }
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    Environment = var.environment.name
  }
}


