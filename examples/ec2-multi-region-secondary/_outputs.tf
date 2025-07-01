output "name" {
  description = "ECS cluster name"
  value       = module.ecs_cluster.name
}

output "id" {
  description = "ECS cluster id"
  value       = module.ecs_cluster.id
}

output "arn" {
  description = "ECS cluster arn"
  value       = module.ecs_cluster.arn
}

output "role_name" {
  description = "IAM role name (from global region)"
  value       = data.aws_iam_role.existing_ecs_role.name
}

output "role_arn" {
  description = "IAM role ARN (from global region)"
  value       = data.aws_iam_role.existing_ecs_role.arn
}

output "role_instance_profile" {
  description = "IAM instance profile name (from global region)"
  value       = data.aws_iam_instance_profile.existing_ecs_instance_profile.name
}
