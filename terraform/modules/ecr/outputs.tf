output "repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.main.repository_url
  # repository_url looks like:
  # 123456789012.dkr.ecr.ap-southeast-2.amazonaws.com/budget-tracker-production
  #
  # this URL is used:
  # 1. when pushing your Docker image from your Mac
  # 2. when ECS pulls the image to run it
  # so both your Mac and ECS need to know this URL
}

output "repository_name" {
  description = "The name of the ECR repository"
  value       = aws_ecr_repository.main.name
  # returns: "budget-tracker-production"
}