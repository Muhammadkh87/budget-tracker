# ─────────────────────────────────────────
# General Variables
# ─────────────────────────────────────────

variable "aws_region" {
  description = "The AWS region where all resources will be created"
  type        = string
  default     = "ap-southeast-2"
}

variable "project_name" {
  description = "The name of the project, used for naming and tagging all resources"
  type        = string
  default     = "budget-tracker"
}

variable "environment" {
  description = "The deployment environment (dev, staging, production)"
  type        = string
  default     = "production"
}

# ─────────────────────────────────────────
# Networking Variables
# ─────────────────────────────────────────

variable "vpc_cidr" {
  description = "The CIDR block for the VPC (defines the IP address range)"
  type        = string
  default     = "10.0.0.0/16"

}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets (one per availability zone)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets (one per availability zone)"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "availability_zones" {
  description = "List of availability zones to deploy resources into"
  type        = list(string)
  default     = ["ap-southeast-2a", "ap-southeast-2b"]
}

# ─────────────────────────────────────────
# ECS Variables
# ─────────────────────────────────────────

variable "container_port" {
  description = "The port our application listens on inside the container"
  type        = number
  default     = 3000
}

variable "task_cpu" {
  description = "The amount of CPU to allocate to the ECS task (in AWS CPU units)"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "The amount of memory to allocate to the ECS task (in MB)"
  type        = number
  default     = 512
}

variable "app_count" {
  description = "Number of ECS tasks to run (how many containers)"
  type        = number
  default     = 1
}

# ─────────────────────────────────────────
# RDS Variables
# ─────────────────────────────────────────

variable "db_name" {
  description = "The name of the PostgreSQL database"
  type        = string
  default     = "budgettracker"
}

variable "db_username" {
  description = "The master username for the PostgreSQL database"
  type        = string
  default     = "budgetadmin"
}

variable "db_password" {
  description = "The master password for the PostgreSQL database"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "The RDS instance size"
  type        = string
  default     = "db.t3.micro"
}