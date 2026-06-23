variable "private_subnet_az1_id" {}
variable "private_subnet_az2_id" {}
variable "application_load_balancer" {}
variable "alb_target_group_arn" {}
variable "ec2_security_group_id" {}
variable "iam_ec2_instance_profile" {}
variable "key_name" {}
variable "project_name" {}
variable "user_data" {
  description = "User data script for ASG EC2 instances"
  type        = string
}
variable "instance_type" {}