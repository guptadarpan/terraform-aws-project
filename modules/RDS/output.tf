output "rds_endpoint" {
  description = "The connection endpoint for the database"
  value       = aws_db_instance.main.endpoint
}

output "rds_db_name" {
  description = "The name of the database"
  value       = aws_db_instance.main.db_name
}
