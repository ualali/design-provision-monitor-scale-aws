terraform {
  required_version = ">=1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>3.0"
    }
  }

  backend "local" {
    path = ".tfstate/terraform.tfstate"
  }
}

# TODO: Designate a cloud provider, region, and credentials
provider "aws" {
  profile = "default"
  region  = "us-east-1"

  default_tags {
    tags = {
      "Project"     = "nd063"
      "Environment" = "udacity"
    }
  }
}

# TODO: provision 4 AWS t2.micro EC2 instances named Udacity T2
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name = "name"
    values = [
      "amzn2-ami-hvm-*-x86_64-gp2",
    ]
  }

  filter {
    name = "owner-alias"
    values = [
      "amazon",
    ]
  }
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.7.0"

  name        = "Udacity SG"
  description = "Security group for SSH administration"
  vpc_id      = "vpc-0ba7067e9b85d42ae"

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH for administration"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "All outbound traffic"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

module "ec2_t2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "3.3.0"
  count   = 4

  name                   = "Udacity T2"
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"
  key_name               = "nd063-717878303627-key"
  monitoring             = true
  vpc_security_group_ids = [module.security_group.security_group_id]
  subnet_id              = "subnet-0f0168e5d86ee0afa"

  depends_on = [
    module.security_group
  ]
}

# TODO: provision 2 m4.large EC2 instances named Udacity M4
module "ec2_m4_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "3.3.0"
  count   = 2

  name                   = "Udacity M4"
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "m4.large"
  key_name               = "nd063-717878303627-key"
  monitoring             = true
  vpc_security_group_ids = [module.security_group.security_group_id]
  subnet_id              = "subnet-0f0168e5d86ee0afa"

  depends_on = [
    module.security_group
  ]
}
