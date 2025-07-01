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
  value       = module.ecs_cluster.role_name
}

output "role_arn" {
  description = "IAM role ARN (from global region)"
  value       = module.ecs_cluster.role_arn
}

output "role_instance_profile" {
  description = "IAM instance profile name (from global region)"
  value       = module.ecs_cluster.role_instance_profile
}
