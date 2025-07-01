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

# Create IAM role that will be shared across regions
resource "aws_iam_role" "ecs_role" {
  name = "${module.context.id}-ecs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = module.context.tags
}

resource "aws_iam_role_policy_attachment" "ecs_role_policy" {
  role       = aws_iam_role.ecs_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ssm_role_policy" {
  role       = aws_iam_role.ecs_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "${module.context.id}-ecs-instance-profile"
  role = aws_iam_role.ecs_role.name

  tags = module.context.tags
}

module "ecs_cluster" {
  source = "../.."

  context = module.context.self

  container_insights_enabled      = true
  capacity_providers_fargate      = false
  capacity_providers_fargate_spot = false
  capacity_providers_ec2 = {
    ec2_default = {
      instance_type               = "t3.medium"
      security_group_ids          = [module.vpc.vpc_default_security_group_id]
      subnet_ids                  = module.subnets.private_subnet_ids
      associate_public_ip_address = false
      min_size                    = 0
      max_size                    = 2
    }
  }

  # Use externally managed IAM role
  create_iam_role        = false
  existing_iam_role_name = aws_iam_role.ecs_role.name

  policy_document = []
}
