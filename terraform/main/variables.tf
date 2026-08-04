variable "region" {
  type    = string
  default = "ap-south-1"
}
variable "project_name" {
  type    = string
  default = "awsinfra"
}
variable "environment" {
  type    = string
  default = "production"
}

variable "vpc_cidr" { type = string }
variable "public_subnet_az1_cidr" { type = string }
variable "public_subnet_az2_cidr" { type = string }

# --- App ports (must match what the containers actually EXPOSE) ---
variable "backend_container_port" {
  description = "Port the Node/Express backend listens on inside the container (Dockerfile EXPOSEs 5000)"
  type        = number
  default     = 5000
}
variable "frontend_container_port" {
  description = "Port nginx listens on inside the frontend container (Dockerfile EXPOSEs 80)"
  type        = number
  default     = 80
}
variable "backend_health_check_path" {
  description = "Backend exposes GET /api/health - NOT /health"
  type        = string
  default     = "/api/health"
}
variable "frontend_health_check_path" {
  type    = string
  default = "/"
}

# --- Images ---
variable "image_tag" {
  description = "Tag used for the initial task def revision Terraform creates; CI/CD registers subsequent revisions"
  type        = string
  default     = "latest"
}
variable "image_retention_count" {
  type    = number
  default = 15
}
variable "backend_repository_name" {
  description = "Must match your existing ECR repo name if you're importing it"
  type        = string
  default     = "luggage-bag-app"
}
variable "frontend_repository_name" {
  description = "Must match your existing ECR repo name if you're importing it"
  type        = string
  default     = "luggage-bag-app-frontend"
}

# --- Sizing ---
variable "backend_task_cpu" {
  type    = number
  default = 512
}
variable "backend_task_memory" {
  type    = number
  default = 1024
}
variable "frontend_task_cpu" {
  description = "nginx serving a static build needs far less than the API"
  type        = number
  default     = 256
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
  type    = number
  default = 30
}
variable "ec2_asg_min_size" {
  type    = number
  default = 2
}
variable "ec2_asg_max_size" {
  type    = number
  default = 6
}
variable "ec2_asg_desired_capacity" {
  type    = number
  default = 2
}
variable "ec2_capacity_target" {
  type    = number
  default = 80
}
variable "log_retention_days" {
  type    = number
  default = 30
}

# --- Env vars ---
variable "backend_container_environment" {
  type    = list(object({ name = string, value = string }))
  default = []
}

variable "frontend_container_environment" {
  type    = list(object({ name = string, value = string }))
  default = []
}

# --- TLS ---
variable "enable_https" {
  description = "Requires an ACM certificate in the same region, validated for your domain"
  type        = bool
  default     = false
}
variable "certificate_arn" {
  type    = string
  default = ""
}

variable "enable_deletion_protection" {
  type    = bool
  default = true
}

# --- GitHub Actions OIDC ---
variable "github_org" {
  description = "GitHub org/username that owns the repo, e.g. durveshyadav3604"
  type        = string
}

variable "github_repo" {
  description = "GitHub repo name, e.g. SparknetTask1"
  type        = string
}