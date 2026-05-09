variable "project_name" {
  description = "Project name used for naming resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where RDS will be created"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for RDS"
  type        = list(string)
  # RDS lives in private subnets
  # never in public subnets
}

variable "rds_sg_id" {
  description = "Security group ID for RDS"
  type        = string
  # comes from security-groups module output
}

variable "db_name" {
  description = "Name of the database"
  type        = string
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
}

variable "db_password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
  # sensitive = true means never printed in logs
}

variable "db_instance_class" {
  description = "RDS instance size"
  type        = string
}