terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
  # >= 1.10 required for native S3 state locking (use_lockfile) in statefile.tf.
  # The existing CI/CD pipeline already pins hashicorp/setup-terraform to 1.14.8.
  required_version = ">= 1.10.0"
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
