output "gke_cluster_name" {
  description = "GKE Cluster name"
  value       = module.gke.cluster_name
}

output "gke_cluster_endpoint" {
  description = "GKE Cluster endpoint"
  value       = module.gke.cluster_endpoint
  sensitive   = true
}

output "gke_region" {
  description = "GKE Cluster region"
  value       = var.region
}

output "cloud_sql_instance_name" {
  description = "Cloud SQL instance name"
  value       = module.cloud_sql.instance_name
}

output "cloud_sql_private_ip" {
  description = "Cloud SQL private IP address"
  value       = module.cloud_sql.private_ip_address
}

output "cloud_sql_connection_name" {
  description = "Cloud SQL connection name (for Cloud SQL Proxy)"
  value       = module.cloud_sql.connection_name
}

output "redis_host" {
  description = "Redis host IP"
  value       = module.redis.host
}

output "redis_port" {
  description = "Redis port"
  value       = module.redis.port
}

output "kong_loadbalancer_ip" {
  description = "Kong Gateway LoadBalancer IP"
  value       = module.kong.loadbalancer_ip
}

output "kong_admin_url" {
  description = "Kong Admin API URL"
  value       = module.kong.admin_url
}

output "keycloak_loadbalancer_ip" {
  description = "Keycloak LoadBalancer IP"
  value       = module.keycloak.loadbalancer_ip
}

output "keycloak_url" {
  description = "Keycloak URL"
  value       = module.keycloak.keycloak_url
}

output "kubectl_context" {
  description = "kubectl context command"
  value       = "gcloud container clusters get-credentials ${module.gke.cluster_name} --region ${var.region}"
}
