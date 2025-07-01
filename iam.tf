module "role" {
  count   = module.context.enabled && var.create_iam_role ? 1 : 0
  source  = "SevenPicoForks/iam-role/aws"
  version = "2.0.2"
  context = module.context.self

  instance_profile_enabled = true
  max_session_duration     = 3600
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  ]
  path                  = "/"
  permissions_boundary  = ""
  policy_description    = "Policy for ECS EC2 role"
  policy_document_count = length(var.policy_document)
  policy_documents      = var.policy_document
  principals = {
    Service = ["ec2.amazonaws.com"]
  }
  role_description = "IAM role for ECS EC2"
  use_fullname     = true
}

# Data sources for existing IAM resources
data "aws_iam_role" "existing" {
  count = module.context.enabled && !var.create_iam_role ? 1 : 0
  name  = var.existing_iam_role_name
}

data "aws_iam_instance_profile" "existing" {
  count = module.context.enabled && !var.create_iam_role ? 1 : 0
  name  = var.existing_iam_role_name
}

# Local values to abstract the conditional logic
locals {
  role_name             = var.create_iam_role ? try(module.role[0].name, "") : try(data.aws_iam_role.existing[0].name, "")
  role_arn              = var.create_iam_role ? try(module.role[0].arn, "") : try(data.aws_iam_role.existing[0].arn, "")
  instance_profile_name = var.create_iam_role ? try(module.role[0].instance_profile, "") : try(data.aws_iam_instance_profile.existing[0].name, "")
}
