variable "vpc_id" {}
variable "vpc_cidr" {}
variable "project_name" {}

variable "backend_container_port" {
  description = "Port the backend (Node/Express) container listens on"
  type        = number
}

variable "frontend_container_port" {
  description = "Port the frontend (nginx) container listens on"
  type        = number
}

