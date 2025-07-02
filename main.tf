locals {
  enabled      = module.context.enabled
  cluster_name = join("", aws_ecs_cluster.default[*].name)

  # Scenario detection and validation locals
  has_fargate_providers = var.capacity_providers_fargate || var.capacity_providers_fargate_spot
  has_ec2_providers     = length(var.capacity_providers_ec2) > 0 || length(var.external_ec2_capacity_providers) > 0
  requires_iam          = local.has_ec2_providers
  scenario              = local.has_fargate_providers && local.has_ec2_providers ? "mixed" : local.has_fargate_providers ? "pure_fargate" : local.has_ec2_providers ? "pure_ec2" : "invalid"

  # IAM role validation
  iam_role_validation = local.has_ec2_providers ? (
    var.create_iam_role || var.existing_iam_role_name != null ? "valid" : "invalid"
  ) : "not_required"

  # Validation error messages
  validate_iam_role_required    = local.iam_role_validation == "invalid" ? tobool("When using EC2 capacity providers (capacity_providers_ec2 or external_ec2_capacity_providers), you must either set create_iam_role=true or provide existing_iam_role_name.") : true
  validate_iam_role_unnecessary = !local.has_ec2_providers && var.existing_iam_role_name != null ? tobool("existing_iam_role_name should not be set when only using Fargate capacity providers (no EC2 capacity providers configured).") : true


  capacity_providers_fargate = [
    for name, is_enabled in {
      FARGATE : var.capacity_providers_fargate,
      FARGATE_SPOT : var.capacity_providers_fargate_spot
    } : name if is_enabled
  ]

  capacity_providers = distinct(concat(
    [for key, value in aws_ecs_capacity_provider.ec2 : value.name],
    [for key, value in aws_ecs_capacity_provider.external_ec2 : value.name],
    local.capacity_providers_fargate
  ))

  default_capacity_strategy = [
    for name, weight in var.default_capacity_strategy.weights : {
      capacity_provider = name,
      weight            = weight,
      base              = var.default_capacity_strategy.base.provider == name ? var.default_capacity_strategy.base.value : null
    }
  ]
}


resource "aws_ecs_cluster" "default" {
  count = local.enabled ? 1 : 0

  name = module.context.id

  setting {
    name  = "containerInsights"
    value = var.container_insights_enabled ? "enabled" : "disabled"
  }

  configuration {
    execute_command_configuration {
      kms_key_id = var.kms_key_id
      logging    = var.logging
      dynamic "log_configuration" {
        for_each = var.logging == "OVERRIDE" ? [var.log_configuration] : []
        content {
          cloud_watch_encryption_enabled = log_configuration.value["cloud_watch_encryption_enabled"]
          cloud_watch_log_group_name     = log_configuration.value["cloud_watch_log_group_name"]
          s3_bucket_name                 = log_configuration.value["s3_bucket_name"]
          s3_bucket_encryption_enabled   = true
          s3_key_prefix                  = log_configuration.value["s3_key_prefix"]
        }
      }
    }
  }

  dynamic "service_connect_defaults" {
    for_each = var.service_discovery_namespace_arn != null ? [var.service_discovery_namespace_arn] : []
    content {
      namespace = service_connect_defaults.value
    }
  }

  tags = module.context.tags
}

resource "aws_ecs_cluster_capacity_providers" "default" {
  count = local.enabled && length(local.capacity_providers) > 0 ? 1 : 0

  cluster_name = local.cluster_name

  capacity_providers = local.capacity_providers

  dynamic "default_capacity_provider_strategy" {
    for_each = local.default_capacity_strategy
    content {
      base              = default_capacity_provider_strategy.value["base"]
      weight            = default_capacity_provider_strategy.value["weight"]
      capacity_provider = default_capacity_provider_strategy.value["capacity_provider"]
    }
  }
}
