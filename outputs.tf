output "postgresql_service_name" {
  description = "PostgreSQL service name"
  value       = "postgresql-${var.environment}"
}

output "api_service_name" {
  description = "API service name"
  value       = "api-${var.environment}"
}
