variable "project_name" {
  description = "Project name used for naming resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ECS will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS tasks"
  type        = list(string)
  # ECS tasks run in PRIVATE subnets
  # not directly accessible from internet
  # traffic comes through ALB only
}

variable "ecs_sg_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

variable "target_group_arn" {
  description = "ALB target group ARN for ECS service"
  type        = string
  # ECS registers containers with this target group
  # so ALB knows where to send traffic
}

variable "ecr_repository_url" {
  description = "ECR repository URL for the Docker image"
  type        = string
  # looks like:
  # 123456789012.dkr.ecr.ap-southeast-2.amazonaws.com/budget-tracker-production
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
}

variable "task_cpu" {
  description = "CPU units for the ECS task"
  type        = number
}

variable "task_memory" {
  description = "Memory for the ECS task in MB"
  type        = number
}

variable "app_count" {
  description = "Number of ECS tasks to run"
  type        = number
}

variable "db_endpoint" {
  description = "RDS database endpoint"
  type        = string
  # passed as environment variable to the container
  # so our Node.js app knows where to find the database
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database username"
  type        = string
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}