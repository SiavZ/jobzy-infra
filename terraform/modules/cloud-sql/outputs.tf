output "instance_name" {
  description = "Cloud SQL instance name"
  value       = google_sql_database_instance.postgres.name
}

output "instance_connection_name" {
  description = "Connection name for Cloud SQL Proxy"
  value       = google_sql_database_instance.postgres.connection_name
}

output "connection_name" {
  description = "Connection name (alias for instance_connection_name)"
  value       = google_sql_database_instance.postgres.connection_name
}

output "private_ip_address" {
  description = "Private IP address"
  value       = google_sql_database_instance.postgres.private_ip_address
}

output "kong_username" {
  description = "Kong database username"
  value       = google_sql_user.kong.name
}

output "kong_password" {
  description = "Kong database password"
  value       = random_password.kong_password.result
  sensitive   = true
}

output "keycloak_username" {
  description = "Keycloak database username"
  value       = google_sql_user.keycloak.name
}

output "keycloak_password" {
  description = "Keycloak database password"
  value       = random_password.keycloak_password.result
  sensitive   = true
}
