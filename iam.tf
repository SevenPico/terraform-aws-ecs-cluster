locals {
  has_ec2_capacity_providers = length(var.capacity_providers_ec2) > 0 || length(var.external_ec2_capacity_providers) > 0
  use_external_role = var.iam_instance_profile_name != null && var.iam_instance_profile_name != ""
  enable_iam_role = local.has_ec2_capacity_providers && !local.use_external_role
}

data "aws_iam_instance_profile" "external" {
  count = local.enabled && local.has_ec2_capacity_providers && !local.enable_iam_role ? 1 : 0
  name  = var.iam_instance_profile_name
}

module "role" {
  source  = "SevenPicoForks/iam-role/aws"
  version = "2.0.2"
  context = module.context.self
  enabled = module.context.enabled && local.enable_iam_role

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
