output "name" {
  description = "ECS cluster name"
  value       = var.enabled ? module.ecs_cluster[0].name : ""
}

output "id" {
  description = "ECS cluster id"
  value       = var.enabled ? module.ecs_cluster[0].id : ""
}

output "arn" {
  description = "ECS cluster arn"
  value       = var.enabled ? module.ecs_cluster[0].arn : ""
}
