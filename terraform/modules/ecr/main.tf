# ─────────────────────────────────────────
# ECR Repository
# ─────────────────────────────────────────

resource "aws_ecr_repository" "main" {
  # the name of our repository in ECR
  name = "${var.project_name}-${var.environment}"
  # result: "budget-tracker-production"
  # this is what you'll see in AWS ECR console

  # image_tag_mutability controls whether image tags can be overwritten
  # MUTABLE   → you can push a new image with the same tag
  # IMMUTABLE → once a tag is used, it can never be overwritten
  # we use MUTABLE for simplicity
  # in strict production you'd use IMMUTABLE for better auditability
  image_tag_mutability = "MUTABLE"

  # enable image scanning on every push
  # AWS automatically scans for known security vulnerabilities
  # in your Docker image and its dependencies
  # completely free and a great security practice
  image_scanning_configuration {
    scan_on_push = true
  }

  # encryption configuration for images stored in ECR
  # AES256 is AWS managed encryption
  # your images are encrypted at rest in ECR storage
  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ecr"
  }
}

# ─────────────────────────────────────────
# ECR Lifecycle Policy
# ─────────────────────────────────────────

resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name

  # lifecycle policies automatically clean up old images
  # without this, every docker push adds a new image forever
  # costs keep growing and storage fills up 😱
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only last 5 images, remove older ones"

        selection = {
          tagStatus   = "any"
          # "any" means apply to all images regardless of tag
          countType   = "imageCountMoreThan"
          countNumber = 5
          # when more than 5 images exist
          # automatically delete the oldest ones
          # keeps storage costs low
          # 5 images means you can roll back up to 5 versions
        }

        action = {
          type = "expire"
          # expire = delete the old images
        }
      }
    ]
  })
}