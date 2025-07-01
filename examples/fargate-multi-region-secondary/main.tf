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

# Data source to reference the existing IAM role created in the global region
data "aws_iam_role" "existing_ecs_role" {
  name = var.global_iam_role_name
}

data "aws_iam_instance_profile" "existing_ecs_instance_profile" {
  name = var.global_iam_role_name
}

module "ecs_cluster" {
  source = "../.."

  context = module.context.self

  container_insights_enabled      = true
  capacity_providers_fargate      = true
  capacity_providers_fargate_spot = true
  capacity_providers_ec2          = {}

  # Use existing IAM role from global region
  create_iam_role        = false
  existing_iam_role_name = var.global_iam_role_name

  policy_document = []
}
