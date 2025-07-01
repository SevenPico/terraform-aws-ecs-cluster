output "name" {
  description = "ECS cluster name"
  value       = module.context.enabled ? local.cluster_name : null
}

output "id" {
  description = "ECS cluster id"
  value       = module.context.enabled ? join("", aws_ecs_cluster.default[*].id) : null
}

output "arn" {
  description = "ECS cluster arn"
  value       = module.context.enabled ? join("", aws_ecs_cluster.default[*].arn) : null
}

output "role_name" {
  description = "IAM role name"
  value       = module.context.enabled ? local.role_name : null
}

output "role_arn" {
  description = "IAM role ARN"
  value       = module.context.enabled ? local.role_arn : null
}

output "role_instance_profile" {
  description = "IAM instance profile name"
  value       = module.context.enabled ? local.instance_profile_name : null
}
