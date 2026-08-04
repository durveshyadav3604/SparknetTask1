variable "project_name" {}
variable "alb_sg_id" {}
variable "public_subnet_az1_id" {}
variable "public_subnet_az2_id" {}
variable "vpc_id" {}

variable "backend_container_port" {
  description = "Port the backend container listens on"
  type        = number
}

variable "frontend_container_port" {
  description = "Port the frontend container listens on"
  type        = number
}

variable "backend_health_check_path" {
  description = "Path the ALB uses to check backend health"
  type        = string
  default     = "/api/health"
}

variable "frontend_health_check_path" {
  description = "Path the ALB uses to check frontend health"
  type        = string
  default     = "/"
}

variable "enable_deletion_protection" {
  description = "Prevent accidental ALB deletion (should be true in production)"
  type        = bool
  default     = true
}

variable "enable_https" {
  description = "Create an HTTPS (:443) listener and redirect :80 to it. Requires certificate_arn."
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ACM certificate ARN for the HTTPS listener (required if enable_https = true)"
  type        = string
  default     = ""
}
