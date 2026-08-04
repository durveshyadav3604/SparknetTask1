output "alb_arn" {
  value = aws_lb.application_load_balancer.arn
}

output "alb_dns_name" {
  value = aws_lb.application_load_balancer.dns_name
}

output "alb_zone_id" {
  value = aws_lb.application_load_balancer.zone_id
}

output "backend_target_group_arn" {
  value = aws_lb_target_group.backend.arn
}

output "frontend_target_group_arn" {
  value = aws_lb_target_group.frontend.arn
}

output "http_listener_arn" {
  value = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  value = try(aws_lb_listener.https[0].arn, null)
}

# The listener the ECS services should depend_on so they don't try to
# register targets before the ALB can actually route to them.
output "app_listener_arn" {
  value = local.app_listener_arn
}
