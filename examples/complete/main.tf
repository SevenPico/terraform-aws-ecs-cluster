provider "aws" {
  region = var.region
}

module "vpc" {
  count                   = var.enabled ? 1 : 0
  source                  = "registry.terraform.io/SevenPico/vpc/aws"
  version                 = "3.0.2"
  ipv4_primary_cidr_block = "172.16.0.0/16"
  context                 = module.context.self
}

module "subnets" {
  count                = var.enabled ? 1 : 0
  source               = "registry.terraform.io/SevenPico/dynamic-subnets/aws"
  version              = "3.1.2"
  availability_zones   = var.availability_zones
  vpc_id               = module.vpc[0].vpc_id
  igw_id               = [module.vpc[0].igw_id]
  ipv4_cidr_block      = [module.vpc[0].vpc_cidr_block]
  nat_gateway_enabled  = false
  nat_instance_enabled = false
  context              = module.context.self
}

module "ecs_cluster" {
  count = var.enabled ? 1 : 0
  source = "../.."

  context = module.context.self

  container_insights_enabled      = true
  capacity_providers_fargate      = true
  capacity_providers_fargate_spot = true
  capacity_providers_ec2 = {
    ec2_default = {
      instance_type               = "t3.medium"
      security_group_ids          = [module.vpc[0].vpc_default_security_group_id]
      subnet_ids                  = module.subnets[0].private_subnet_ids
      associate_public_ip_address = false
      min_size                    = 0
      max_size                    = 2
    }
  }
  external_ec2_capacity_providers = {}
  policy_document = []
}
