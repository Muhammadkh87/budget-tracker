# ─────────────────────────────────────────
# VPC Module
# ─────────────────────────────────────────

module "vpc" {
  source = "./modules/vpc"
  # source tells Terraform where to find this module
  # ./ means look in the current terraform/ directory

  # passing root variables DOWN into the vpc module
  # left side  = variable name in modules/vpc/variables.tf
  # right side = value from root variables.tf
  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

# ─────────────────────────────────────────
# Security Groups Module
# ─────────────────────────────────────────

module "security_groups" {
  source = "./modules/security-groups"

  project_name   = var.project_name
  environment    = var.environment
  container_port = var.container_port

  # vpc_id comes FROM the vpc module output
  # not from variables.tf
  # this is modules talking to each other! 
  vpc_id = module.vpc.vpc_id
}

# ─────────────────────────────────────────
# ECR Module
# ─────────────────────────────────────────

module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
  environment  = var.environment
}

# ─────────────────────────────────────────
# RDS Module
# ─────────────────────────────────────────

module "rds" {
  source = "./modules/rds"

  project_name = var.project_name
  environment  = var.environment

  # networking comes from vpc module
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  # security group comes from security_groups module
  rds_sg_id = module.security_groups.rds_sg_id

  # database credentials come from root variables
  # which get their values from terraform.tfvars
  db_name           = var.db_name
  db_username       = var.db_username
  db_password       = var.db_password
  db_instance_class = var.db_instance_class
}

# ─────────────────────────────────────────
# ALB Module
# ─────────────────────────────────────────

module "alb" {
  source = "./modules/alb"

  project_name   = var.project_name
  environment    = var.environment
  container_port = var.container_port

  # networking comes from vpc module
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids

  # security group comes from security_groups module
  alb_sg_id = module.security_groups.alb_sg_id
}

# ─────────────────────────────────────────
# ECS Module
# ─────────────────────────────────────────

module "ecs" {
  source = "./modules/ecs"

  project_name   = var.project_name
  environment    = var.environment
  aws_region     = var.aws_region
  container_port = var.container_port
  task_cpu       = var.task_cpu
  task_memory    = var.task_memory
  app_count      = var.app_count

  # networking comes from vpc module
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  # security group comes from security_groups module
  ecs_sg_id = module.security_groups.ecs_sg_id

  # ECR repository URL comes from ecr module
  ecr_repository_url = module.ecr.repository_url

  # target group comes from alb module
  # ECS registers containers with this
  target_group_arn = module.alb.target_group_arn

  # database details come from rds module
  db_endpoint = module.rds.db_endpoint
  db_name     = module.rds.db_name
  db_username = module.rds.db_username

  # password comes from root variables
  db_password = var.db_password
}