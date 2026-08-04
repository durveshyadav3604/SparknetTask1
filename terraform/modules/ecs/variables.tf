variable "project_name" {}
variable "region" {}

variable "vpc_id" {
  description = "Needed for the mongo/EFS security groups and the Cloud Map private DNS namespace"
  type        = string
}

variable "public_subnet_ids" {
  type = list(string)
}
variable "ecs_instance_sg_id" {
  description = "SG attached to the EC2 container instances - bridge mode routes all container traffic through the host, so this is the only task-facing SG needed"
}

variable "backend_target_group_arn" {}
variable "frontend_target_group_arn" {}

variable "backend_image_url" {
  description = "ECR repository URL for the backend image (without tag)"
  type        = string
}
variable "frontend_image_url" {
  description = "ECR repository URL for the frontend image (without tag)"
  type        = string
}
variable "image_tag" {
  description = "Image tag Terraform uses for the *initial* task definition revision only (CI/CD owns subsequent revisions)"
  type        = string
  default     = "latest"
}

variable "backend_container_port" {
  type    = number
  default = 5000
}
variable "frontend_container_port" {
  type    = number
  default = 80
}

variable "backend_container_environment" {
  description = "Plain (non-secret) env vars for the backend container"
  type        = list(object({ name = string, value = string }))
  default     = []
}
variable "frontend_container_environment" {
  description = "Plain env vars for the frontend container (REACT_APP_* vars are baked at build time, not here)"
  type        = list(object({ name = string, value = string }))
  default     = []
}

variable "backend_task_cpu" {
  type    = number
  default = 512
}
variable "backend_task_memory" {
  type    = number
  default = 1024
}
variable "frontend_task_cpu" {
  type    = number
  default = 256
}
variable "frontend_task_memory" {
  type    = number
  default = 512
}

variable "desired_count" {
  type    = number
  default = 2
}
variable "min_capacity" {
  type    = number
  default = 2
}
variable "max_capacity" {
  type    = number
  default = 6
}

variable "ec2_instance_type" {
  description = "Instance type for ECS container instances"
  type        = string
  default     = "t3.medium"
}
variable "ec2_key_name" {
  description = "EC2 key pair name for SSH access to container instances. Leave empty to rely on SSM Session Manager instead."
  type        = string
  default     = ""
}
variable "ec2_root_volume_size" {
  description = "Root EBS volume size (GiB) for container instances"
  type        = number
  default     = 30
}
variable "ec2_asg_min_size" {
  description = "Minimum number of EC2 container instances"
  type        = number
  default     = 2
}
variable "ec2_asg_max_size" {
  description = "Maximum number of EC2 container instances"
  type        = number
  default     = 6
}
variable "ec2_asg_desired_capacity" {
  description = "Desired number of EC2 container instances at apply time (the ECS managed-scaling capacity provider adjusts this afterwards)"
  type        = number
  default     = 2
}
variable "ec2_capacity_target" {
  description = "Target % of ASG capacity ECS tries to keep in use before scaling instances out (managed scaling)"
  type        = number
  default     = 80
}

variable "log_retention_days" {
  type    = number
  default = 30
}

