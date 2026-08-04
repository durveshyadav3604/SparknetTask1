# The original module used `data "aws_ecr_repository"` to *look up*
# pre-existing repos. That's fragile - `terraform apply` fails on a clean
# account/region until someone manually creates the repos out-of-band first.
# Managing them here makes the stack self-contained and reproducible.

resource "aws_ecr_repository" "backend" {
  name = var.backend_repository_name
  # MUTABLE for now because the current CI/CD only ever pushes ":latest" -
  # IMMUTABLE would reject every push after the first. Switch to IMMUTABLE
  # once CI/CD tags by commit SHA (see ci-cd/ci-cd.yml in this repo).
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = { Name = "${var.project_name}-backend" }
}

resource "aws_ecr_repository" "frontend" {
  name                  = var.frontend_repository_name
  image_tag_mutability  = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = { Name = "${var.project_name}-frontend" }
}

# Keep only the last N images per repo so storage cost doesn't grow forever
resource "aws_ecr_lifecycle_policy" "backend" {
  repository = aws_ecr_repository.backend.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last ${var.image_retention_count} images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = var.image_retention_count
      }
      action = { type = "expire" }
    }]
  })
}

resource "aws_ecr_lifecycle_policy" "frontend" {
  repository = aws_ecr_repository.frontend.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last ${var.image_retention_count} images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = var.image_retention_count
      }
      action = { type = "expire" }
    }]
  })
}
