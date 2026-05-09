output "db_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = aws_db_instance.main.endpoint
  # endpoint looks like:
  # budget-tracker-production-db.xxxxx.ap-southeast-2.rds.amazonaws.com:5432
  # ECS uses this to connect to the database
}

output "db_name" {
  description = "The database name"
  value       = aws_db_instance.main.db_name
}

output "db_username" {
  description = "The database username"
  value       = aws_db_instance.main.username
}