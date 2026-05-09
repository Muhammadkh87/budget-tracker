# These are the values this module passes back out
# Other modules (ECS, RDS, ALB) will use these

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
  # other modules reference this as:
  # module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
  # [*] means "all items in the list"
  # returns ["subnet-abc123", "subnet-def456"]
  # the load balancer will use these
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
  # ECS and RDS will use these
}