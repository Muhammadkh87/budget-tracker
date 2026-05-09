variable "project_name" {
  description = "Project name used for naming resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID where security groups will be created"
  type        = string
  # notice this comes from the VPC module output
  # root main.tf will pass module.vpc.vpc_id here
  # this is how modules talk to each other!
}

variable "container_port" {
  description = "The port our application listens on"
  type        = number
}