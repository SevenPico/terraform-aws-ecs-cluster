provider "aws" {
  region = var.region
}

module "vpc" {
  source                  = "registry.terraform.io/SevenPico/vpc/aws"
  version                 = "3.0.2"
  ipv4_primary_cidr_block = "172.19.0.0/16"
  context                 = module.context.self
}

module "subnets" {
  source               = "registry.terraform.io/SevenPico/dynamic-subnets/aws"
  version              = "3.1.2"
  availability_zones   = var.availability_zones
  vpc_id               = module.vpc.vpc_id
  igw_id               = [module.vpc.igw_id]
  ipv4_cidr_block      = [module.vpc.vpc_cidr_block]
  nat_gateway_enabled  = true
  nat_instance_enabled = false
  context              = module.context.self
}

module "ecs_cluster" {
  source = "../.."

  context = module.context.self

  container_insights_enabled      = var.container_insights_enabled
  capacity_providers_fargate      = var.capacity_providers_fargate
  capacity_providers_fargate_spot = var.capacity_providers_fargate_spot
  capacity_providers_ec2          = var.capacity_providers_ec2
  external_ec2_capacity_providers = var.external_ec2_capacity_providers

  # Pure Fargate - no IAM needed
  create_iam_role        = var.create_iam_role
  existing_iam_role_name = var.existing_iam_role_name

  policy_document = var.policy_document
}
