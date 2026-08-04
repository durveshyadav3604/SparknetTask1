variable "project_name" {}

variable "backend_repository_name" {
  description = "Must match your existing repo name exactly if importing (e.g. luggage-bag-app) - ECR names are immutable, so this can't be changed later without recreating the repo."
  type        = string
  default     = "luggage-bag-app"
}

variable "frontend_repository_name" {
  description = "Must match your existing repo name exactly if importing (e.g. luggage-bag-app-frontend)"
  type        = string
  default     = "luggage-bag-app-frontend"
}

variable "image_retention_count" {
  description = "How many images to keep per repository before expiring the oldest"
  type        = number
  default     = 15
}
