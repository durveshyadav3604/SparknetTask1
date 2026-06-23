data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# terraform aws launch template
resource "aws_launch_template" "ec2_asg" {
  name                  = "my-launch-template"
  image_id              = data.aws_ami.amazon_linux.id
  key_name              = "linux-key2"
  instance_type         = var.instance_type
  # Enable detailed monitoring for better right-sizing data
  monitoring {
    enabled = true
  }
  iam_instance_profile {
    name = var.iam_ec2_instance_profile.name
  }
  user_data = base64encode(var.user_data)
  vpc_security_group_ids = [var.ec2_security_group_id]
  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_autoscaling_group" "asg-tf" {
  name             = "${var.project_name}-ASG"
  desired_capacity = 2
  max_size         = 3
  min_size         = 1
  force_delete     = true
  depends_on       = [var.application_load_balancer]
  target_group_arns = [var.alb_target_group_arn]
  health_check_type = "ELB"

  vpc_zone_identifier = [var.private_subnet_az1_id, var.private_subnet_az2_id]

  # RIGHT-SIZING: Mixed instances policy
  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.ec2_asg.id
        version            = aws_launch_template.ec2_asg.latest_version
      }

      # List of right-sized instance overrides (cheapest first)
      override {
        instance_type     = "c7i-flex.large"
        weighted_capacity = "1"
      }
      override {
        instance_type     = "m7i-flex.large"
        weighted_capacity = "2"
      }
    }

    instances_distribution {
      on_demand_base_capacity                  = 1     # Keep at least 1 On-Demand
      on_demand_percentage_above_base_capacity = 0     # Rest as Spot = ~70% savings
      spot_allocation_strategy                 = "price-capacity-optimized"
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-ASG"
    propagate_at_launch = true
  }
}
# Scale DOWN at 8 PM IST (14:30 UTC) on weekdays
resource "aws_autoscaling_schedule" "scale_down_night" {
  scheduled_action_name  = "${var.project_name}-scale-down-night"
  min_size               = 1
  max_size               = 2
  desired_capacity       = 1
  recurrence             = "30 14 * * MON-FRI"   # 8 PM IST = 14:30 UTC
  autoscaling_group_name = aws_autoscaling_group.asg-tf.name
}

# Scale UP at 8 AM IST (02:30 UTC) on weekdays
resource "aws_autoscaling_schedule" "scale_up_morning" {
  scheduled_action_name  = "${var.project_name}-scale-up-morning"
  min_size               = 1
  max_size               = 3
  desired_capacity       = 2
  recurrence             = "30 2 * * MON-FRI"    # 8 AM IST = 02:30 UTC
  autoscaling_group_name = aws_autoscaling_group.asg-tf.name
}

# Scale DOWN on weekends (Saturday midnight IST)
resource "aws_autoscaling_schedule" "scale_down_weekend" {
  scheduled_action_name  = "${var.project_name}-scale-down-weekend"
  min_size               = 1
  max_size               = 1
  desired_capacity       = 1
  recurrence             = "30 18 * * FRI"        # Friday 12 AM IST = Friday 18:30 UTC
  autoscaling_group_name = aws_autoscaling_group.asg-tf.name
}
