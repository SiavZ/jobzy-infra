# =============================================================================
# Cloud SQL MySQL Module Outputs
# =============================================================================

output "instance_name" {
  description = "Cloud SQL instance name"
  value       = google_sql_database_instance.mysql.name
}

output "instance_connection_name" {
  description = "Connection name for Cloud SQL Proxy"
  value       = google_sql_database_instance.mysql.connection_name
}

output "private_ip_address" {
  description = "Private IP address"
  value       = google_sql_database_instance.mysql.private_ip_address
}

output "database_names" {
  description = "Map of database names"
  value       = { for k, v in google_sql_database.databases : k => v.name }
}

output "database_users" {
  description = "Map of database usernames"
  value       = { for k, v in google_sql_user.users : k => v.name }
}

output "database_passwords" {
  description = "Map of database passwords"
  value       = { for k, v in random_password.db_passwords : k => v.result }
  sensitive   = true
}

output "replica_instance_names" {
  description = "Read replica instance names"
  value       = var.environment == "prod" && var.create_read_replica ? [for r in google_sql_database_instance.read_replica : r.name] : []
}

output "replica_private_ips" {
  description = "Read replica private IPs"
  value       = var.environment == "prod" && var.create_read_replica ? [for r in google_sql_database_instance.read_replica : r.private_ip_address] : []
}
