# ─────────────────────────────────────────
# General Variables
# ─────────────────────────────────────────

variable "aws_region" {
  description = "The AWS region where all resources will be created"
  type        = string
  default     = "ap-southeast-2"
  # ap-southeast-2 is Sydney — closest to Adelaide
  # we set a default so we dont have to specify it every time
  # but it can be overridden in terraform.tfvars
}

variable "project_name" {
  description = "The name of the project, used for naming and tagging all resources"
  type        = string
  default     = "budget-tracker"
  # this flows through to every resource name
  # e.g. budget-tracker-vpc, budget-tracker-ecs etc
  # keeps everything consistent and easy to find in AWS console
}

variable "environment" {
  description = "The deployment environment (dev, staging, production)"
  type        = string
  default     = "production"
  # in a real company you'd have:
  # dev         → developers testing new features
  # staging     → final testing before release
  # production  → real users
  # we only have one environment but naming it properly
  # shows good practice to interviewers
}

# ─────────────────────────────────────────
# Networking Variables
# ─────────────────────────────────────────

variable "vpc_cidr" {
  description = "The CIDR block for the VPC (defines the IP address range)"
  type        = string
  default     = "10.0.0.0/16"
  # CIDR defines the range of IP addresses available in your VPC
  # 10.0.0.0/16 gives us 65,536 possible IP addresses
  # more than enough for our project
  # we'll break this down further when we build the VPC module
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets (one per availability zone)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  # we have TWO subnets for high availability
  # each subnet lives in a different availability zone
  # if one zone goes down, the other keeps running
  # /24 gives us 256 IP addresses per subnet
  # public subnets → face the internet (load balancer lives here)
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets (one per availability zone)"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
  # private subnets → no direct internet access
  # ECS containers and RDS database live here
  # they can only be reached through the load balancer
  # this is a security best practice
}

variable "availability_zones" {
  description = "List of availability zones to deploy resources into"
  type        = list(string)
  default     = ["ap-southeast-2a", "ap-southeast-2b"]
  # availability zones are physically separate data centers
  # within the same region (Sydney)
  # spreading across two zones = high availability
  # if ap-southeast-2a has a power outage
  # ap-southeast-2b keeps everything running
}

# ─────────────────────────────────────────
# ECS Variables
# ─────────────────────────────────────────

variable "container_port" {
  description = "The port our application listens on inside the container"
  type        = number
  default     = 3000
  # this matches the PORT we defined in docker-compose.yml
  # and the EXPOSE 3000 in our Dockerfile
  # everything needs to agree on the same port
}

variable "task_cpu" {
  description = "The amount of CPU to allocate to the ECS task (in AWS CPU units)"
  type        = number
  default     = 256
  # AWS measures CPU in units where 1024 = 1 vCPU
  # 256 = 0.25 vCPU which is plenty for our small app
  # and keeps costs low on AWS free tier
}

variable "task_memory" {
  description = "The amount of memory to allocate to the ECS task (in MB)"
  type        = number
  default     = 512
  # 512 MB of RAM for our container
  # more than enough for our Node.js app
  # can be increased later if needed
}

variable "app_count" {
  description = "Number of ECS tasks to run (how many containers)"
  type        = number
  default     = 1
  # in production you'd run 2 or more for high availability
  # we use 1 to keep costs down while learning
  # increasing this is as simple as changing the number here
}

# ─────────────────────────────────────────
# RDS Variables
# ─────────────────────────────────────────

variable "db_name" {
  description = "The name of the PostgreSQL database"
  type        = string
  default     = "budgettracker"
  # no hyphens allowed in PostgreSQL database names
  # so we use budgettracker instead of budget-tracker
}

variable "db_username" {
  description = "The master username for the PostgreSQL database"
  type        = string
  default     = "budgetadmin"
  # the admin user for the database
  # never use "admin" or "root" as username
  # too obvious and a security risk
}

variable "db_password" {
  description = "The master password for the PostgreSQL database"
  type        = string
  sensitive   = true
  # NO default value here — this is intentional!
  # sensitive = true means Terraform will never
  # print this value in logs or terminal output
  # the actual password lives in terraform.tfvars only
  # which is gitignored and never pushed to GitHub
}

variable "db_instance_class" {
  description = "The RDS instance size"
  type        = string
  default     = "db.t3.micro"
  # db.t3.micro is the smallest RDS instance
  # eligible for AWS free tier
}