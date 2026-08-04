# create application load balancer
resource "aws_lb" "application_load_balancer" {
  name                       = "${var.project_name}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [var.alb_sg_id]
  subnets                    = [var.public_subnet_az1_id, var.public_subnet_az2_id]
  enable_deletion_protection = var.enable_deletion_protection
  drop_invalid_header_fields = true

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# Backend target group - target_type "instance" registers the EC2 host's
# dynamic port (bridge network mode: containers map to a random host port,
# no per-task ENI like awsvpc). ECS updates the registered port on every
# deploy; the "port" field below is just the target group default.
resource "aws_lb_target_group" "backend" {
  name        = "${var.project_name}-backend-tg"
  target_type = "instance"
  port        = var.backend_container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    interval            = 30
    path                = var.backend_health_check_path
    port                = "traffic-port"
    timeout             = 5
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  # Short deregistration delay so deploys drain fast
  deregistration_delay = 30

  lifecycle {
    create_before_destroy = true
  }

  tags = { Name = "${var.project_name}-backend-tg" }
}

# Frontend target group (nginx serving the React build) - "instance" type,
# same reasoning as backend above.
resource "aws_lb_target_group" "frontend" {
  name        = "${var.project_name}-frontend-tg"
  target_type = "instance"
  port        = var.frontend_container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    path                = var.frontend_health_check_path
    port                = "traffic-port"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }

  deregistration_delay = 30

  lifecycle {
    create_before_destroy = true
  }

  tags = { Name = "${var.project_name}-frontend-tg" }
}

# --- HTTP listener on :80 ---
# If HTTPS is enabled, :80 exists only to redirect to :443 (best practice:
# never serve app traffic unencrypted). Otherwise it serves the app directly
# (e.g. for a quick demo without an ACM cert / domain yet).
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.application_load_balancer.arn
  port               = 80
  protocol           = "HTTP"

  dynamic "default_action" {
    for_each = var.enable_https ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = var.enable_https ? [] : [1]
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.frontend.arn
    }
  }
}

# --- HTTPS listener on :443 (created only when a cert is supplied) ---
resource "aws_lb_listener" "https" {
  count = var.enable_https ? 1 : 0

  load_balancer_arn = aws_lb.application_load_balancer.arn
  port               = 443
  protocol           = "HTTPS"
  ssl_policy         = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn    = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

locals {
  # Whichever listener is actually terminating app traffic is where the
  # /api/* routing rule belongs.
  app_listener_arn = var.enable_https ? aws_lb_listener.https[0].arn : aws_lb_listener.http.arn
}

# --- Direct backend listener on :5000 ---
# Separate from the /api/* rule on :80/:443 - lets clients hit the backend
# directly on its own port without the /api prefix, e.g. for testing.
resource "aws_lb_listener" "backend_direct" {
  load_balancer_arn = aws_lb.application_load_balancer.arn
  port               = var.backend_container_port
  protocol           = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

# Path-based routing: everything goes to the frontend (React SPA) except
# /api/* which goes to the backend. This lets frontend and backend share
# one ALB + one domain, which also sidesteps the CORS configuration the
# original app needed when frontend and backend lived on separate hosts.
resource "aws_lb_listener_rule" "api_to_backend" {
  listener_arn = local.app_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}
