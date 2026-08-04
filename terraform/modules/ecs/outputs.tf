output "cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "asg_name" {
  value = aws_autoscaling_group.ecs.name
}

output "capacity_provider_name" {
  value = aws_ecs_capacity_provider.ec2.name
}

output "backend_service_name" {
  value = aws_ecs_service.backend.name
}
output "frontend_service_name" {
  value = aws_ecs_service.frontend.name
}

output "backend_task_family" {
  value = aws_ecs_task_definition.backend.family
}
output "frontend_task_family" {
  value = aws_ecs_task_definition.frontend.family
}

output "backend_log_group_name" {
  value = aws_cloudwatch_log_group.backend.name
}
output "frontend_log_group_name" {
  value = aws_cloudwatch_log_group.frontend.name
}

output "task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution_role.arn
}
output "task_role_arn" {
  value = aws_iam_role.ecs_task_role.arn
}
