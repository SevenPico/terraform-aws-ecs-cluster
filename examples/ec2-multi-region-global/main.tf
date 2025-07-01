provider "aws" {
  region = var.region
}

module "vpc" {
  source                  = "registry.terraform.io/SevenPico/vpc/aws"
  version                 = "3.0.2"
  ipv4_primary_cidr_block = "172.16.0.0/16"
  context                 = module.context.self
}

module "subnets" {
  source               = "registry.terraform.io/SevenPico/dynamic-subnets/aws"
  version              = "3.1.2"
  availability_zones   = var.availability_zones
  vpc_id               = module.vpc.vpc_id
  igw_id               = [module.vpc.igw_id]
  ipv4_cidr_block      = [module.vpc.vpc_cidr_block]
  nat_gateway_enabled  = false
  nat_instance_enabled = false
  context              = module.context.self
}

module "ecs_cluster" {
  source = "../.."

  context = module.context.self

  container_insights_enabled      = true
  capacity_providers_fargate      = false
  capacity_providers_fargate_spot = false
  capacity_providers_ec2 = {
    ec2_default = {
      name                        = "ec2_default_global"
      instance_type               = "t3.medium"
      security_group_ids          = [module.vpc.vpc_default_security_group_id]
      subnet_ids                  = module.subnets.private_subnet_ids
      associate_public_ip_address = false
      min_size                    = 0
      max_size                    = 2
    }
  }

  # Create IAM role that will be shared across regions
  create_iam_role = true

  policy_document = []
}
