# ALB SG — faces internet
# Opens 80/443 for normal app traffic, plus 5000 for a direct listener to
# the backend target group (bypasses the /api/* path-based rule on 80/443).
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "ALB: HTTP/HTTPS + direct backend port from internet"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Only serves traffic when HTTPS is enabled (certificate_arn supplied).
  # Kept unconditional here because a security group rule costs nothing
  # idle; the *listener* on 443 is what's actually conditional (alb module).
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Direct backend port from internet"
    from_port   = var.backend_container_port
    to_port     = var.backend_container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-alb-sg" }
}

# ECS container-instance SG — bridge network mode maps container ports onto
# the EC2 host itself (no separate task ENI, unlike awsvpc), so all
# ALB-to-container traffic lands on this one security group instead of a
# separate task-level SG.
resource "aws_security_group" "ecs_instance_sg" {
  name        = "${var.project_name}-ecs-instance-sg"
  description = "ECS EC2 container instances - bridge mode: ALB reaches containers via host ports"
  vpc_id      = var.vpc_id

  # SSH access. Left open to the internet only because no admin CIDR was
  # supplied - tighten this to your own IP/VPN range, or drop it entirely
  # and rely on SSM Session Manager (already granted via
  # AmazonSSMManagedInstanceCore on the instance role in the ecs module).
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "Frontend app port from ALB"
    from_port       = var.frontend_container_port
    to_port         = var.frontend_container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description     = "Backend app port from ALB"
    from_port       = var.backend_container_port
    to_port         = var.backend_container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Docker's dynamic host-port range for bridge mode. Task definitions map
  # container ports with hostPort omitted (0), so Docker/ECS pick a random
  # free port in this range each time a task starts, and the ALB target
  # group is updated with whatever port it picked. The ALB needs the whole
  # range open, not just one port, since it changes on every deploy.
  ingress {
    description     = "ECS dynamic host port range (bridge mode) from ALB"
    from_port       = 32768
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-ecs-instance-sg" }
}
