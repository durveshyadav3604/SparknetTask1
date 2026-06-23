terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.region
}

#createvpc
module "vpc" {
  source                  = "../modules/vpc"
  region                  = var.region
  project_name            = var.project_name
  vpc_cidr                = var.vpc_cidr
  public_subnet_az1_cidr  = var.public_subnet_az1_cidr
  public_subnet_az2_cidr  = var.public_subnet_az2_cidr
  private_subnet_az1_cidr = var.private_subnet_az1_cidr
  private_subnet_az2_cidr = var.private_subnet_az2_cidr
  secure_subnet_az1_cidr  = var.secure_subnet_az1_cidr
  secure_subnet_az2_cidr  = var.secure_subnet_az2_cidr
}


#create nat gateway
module "natgateway" {
  source                = "../modules/natgateway"
  public_subnet_az1_id  = module.vpc.public_subnet_az1_id
  internet_gateway      = module.vpc.internet_gateway
  public_subnet_az2_id  = module.vpc.public_subnet_az2_id
  vpc_id                = module.vpc.vpc_id
  private_subnet_az1_id = module.vpc.private_subnet_az1_id
  private_subnet_az2_id = module.vpc.private_subnet_az2_id
}

# create alb
module "application_load_balancer" {
  source               = "../modules/alb"
  project_name         = module.vpc.project_name
  alb_sg_id            = module.security_group.alb_sg_id
  public_subnet_az1_id = module.vpc.public_subnet_az1_id
  public_subnet_az2_id = module.vpc.public_subnet_az2_id
  vpc_id               = module.vpc.vpc_id
}

# create ec2
module "ec2" {
  source                = "../modules/ec2"
  vpc_id                = module.vpc.vpc_id
  region                = var.region
  ec2_security_group_id = module.security_group.ec2_security_group_id
}

# create ASG
module "asg" {
  source                    = "../modules/asg"
  project_name              = module.vpc.project_name
  private_subnet_az1_id     = module.vpc.private_subnet_az1_id
  private_subnet_az2_id     = module.vpc.private_subnet_az2_id
  application_load_balancer = module.application_load_balancer.application_load_balancer
  alb_target_group_arn      = module.application_load_balancer.alb_target_group_arn
  ec2_security_group_id     = module.security_group.ec2_security_group_id
  instance_type             = var.instance_type
  key_name                  = var.key_name
  iam_ec2_instance_profile  = module.ec2.iam_ec2_instance_profile
  user_data                 = file("${path.module}/userdata.sh")
}

# create security group
module "security_group" {
  source   = "../modules/security_group"
  vpc_id   = module.vpc.vpc_id
  vpc_cidr = var.vpc_cidr
}
