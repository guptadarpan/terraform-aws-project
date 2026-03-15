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

module "vpc" {
  source = "../../modules/vpc"

  env_name              = var.env_name
  vpc_cidr              = var.vpc_cidr
  public_subnet_cidr    = var.public_subnet_cidr
  private_subnet_cidr   = var.private_subnet_cidr
  private_subnet_cidr_2 = var.private_subnet_cidr_2
  my_ip                 = var.my_ip
}

module "ec2" {
  source = "../../modules/ec2"

  env_name         = var.env_name
  ami_id           = var.ami_id
  public_subnet_id = module.vpc.public_subnet_id 
  bastion_sg_id    = module.vpc.bastion_sg_id      
  vpc_id           = module.vpc.vpc_id           
  key_name         = var.key_name
  my_ip            = var.my_ip
}

module "rds" {
  source = "../../modules/rds"

  env_name           = var.env_name
  db_username        = var.db_username
  db_password        = var.db_password
  private_subnet_ids = module.vpc.private_subnet_ids  
  rds_sg_id          = module.vpc.rds_sg_id           
  vpc_id             = module.vpc.vpc_id              
}
