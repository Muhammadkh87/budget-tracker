variable "project_name" {
  description = "Project name used for naming resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ALB will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ALB"
  type        = list(string)
  # ALB lives in PUBLIC subnets
  # it needs to be reachable from internet
}

variable "alb_sg_id" {
  description = "Security group ID for the ALB"
  type        = string
  # comes from security-groups module output
}

variable "container_port" {
  description = "The port our application listens on"
  type        = number
  # ALB forwards traffic to this port on ECS
}