output "app_url" {
  description = "The URL of the application"
  value       = "http://${module.alb.alb_dns_name}"
  # after terraform apply you'll see:
  # app_url = "http://budget-tracker-production-alb-123456.ap-southeast-2.elb.amazonaws.com"

}

output "ecr_repository_url" {
  description = "ECR repository URL for pushing Docker images"
  value       = module.ecr.repository_url
  # push your Docker image
  # before ECS can pull and run it
}

output "rds_endpoint" {
  description = "RDS database endpoint"
  value       = module.rds.db_endpoint
  # useful for connecting to the database
  # for debugging or running migrations
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.ecs_cluster_name
  # useful for AWS CLI commands
  # e.g. checking running tasks
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.ecs.ecs_service_name
}