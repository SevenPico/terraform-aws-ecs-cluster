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
  description = "IAM role name (created externally)"
  value       = aws_iam_role.ecs_role.name
}

output "role_arn" {
  description = "IAM role ARN (created externally)"
  value       = aws_iam_role.ecs_role.arn
}

output "role_instance_profile" {
  description = "IAM instance profile name (created externally)"
  value       = aws_iam_instance_profile.ecs_instance_profile.name
}
