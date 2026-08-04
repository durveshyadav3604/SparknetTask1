output "alb_dns_name" {
  description = "Point your domain's DNS (or test directly) at this. Frontend is served at /, backend API at /api/*"
  value       = module.application_load_balancer.alb_dns_name
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}
output "backend_service_name" {
  value = module.ecs.backend_service_name
}
output "frontend_service_name" {
  value = module.ecs.frontend_service_name
}

output "backend_ecr_repository_url" {
  value = module.ecr.backend_repository_url
}
output "frontend_ecr_repository_url" {
  value = module.ecr.frontend_repository_url
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "github_actions_app_deploy_role_arn" {
  description = "Set as the AWS_ROLE_ARN secret in GitHub for the app build/deploy pipeline"
  value       = module.github_oidc_app_deploy.role_arn
}

output "github_actions_terraform_role_arn" {
  description = "Set as the AWS_TERRAFORM_ROLE_ARN secret in GitHub for the terraform.yml workflow"
  value       = module.github_oidc_terraform.role_arn
}
