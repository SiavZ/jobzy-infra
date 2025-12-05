# =============================================================================
# Jobzy Platform - Terraform Outputs
# =============================================================================

# =============================================================================
# VPC & NETWORKING
# =============================================================================

output "vpc_network_name" {
  description = "VPC network name"
  value       = module.vpc.network_name
}

output "vpc_network_id" {
  description = "VPC network ID"
  value       = module.vpc.network_id
}

output "gke_subnet_name" {
  description = "GKE subnet name"
  value       = module.vpc.gke_subnet_name
}

# =============================================================================
# GKE CLUSTER
# =============================================================================

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

output "kubectl_context" {
  description = "kubectl context command"
  value       = "gcloud container clusters get-credentials ${module.gke.cluster_name} --region ${var.region} --project ${var.project_id}"
}

# =============================================================================
# CLOUD SQL - POSTGRESQL
# =============================================================================

output "postgres_instance_name" {
  description = "PostgreSQL instance name"
  value       = module.cloud_sql_postgres.instance_name
}

output "postgres_private_ip" {
  description = "PostgreSQL private IP address"
  value       = module.cloud_sql_postgres.private_ip_address
}

output "postgres_connection_name" {
  description = "PostgreSQL connection name (for Cloud SQL Proxy)"
  value       = module.cloud_sql_postgres.instance_connection_name
}

output "postgres_databases" {
  description = "PostgreSQL database names"
  value       = module.cloud_sql_postgres.database_names
}

# =============================================================================
# CLOUD SQL - MYSQL
# =============================================================================

output "mysql_instance_name" {
  description = "MySQL instance name"
  value       = module.cloud_sql_mysql.instance_name
}

output "mysql_private_ip" {
  description = "MySQL private IP address"
  value       = module.cloud_sql_mysql.private_ip_address
}

output "mysql_connection_name" {
  description = "MySQL connection name (for Cloud SQL Proxy)"
  value       = module.cloud_sql_mysql.instance_connection_name
}

output "mysql_databases" {
  description = "MySQL database names"
  value       = module.cloud_sql_mysql.database_names
}

# =============================================================================
# REDIS
# =============================================================================

output "redis_host" {
  description = "Redis host IP"
  value       = module.redis.host
}

output "redis_port" {
  description = "Redis port"
  value       = module.redis.port
}

output "redis_connection_string" {
  description = "Redis connection string"
  value       = "redis://${module.redis.host}:${module.redis.port}"
}

# =============================================================================
# CLOUD STORAGE
# =============================================================================

output "storage_buckets" {
  description = "Cloud Storage bucket names"
  value       = module.cloud_storage.all_bucket_names
}

output "media_bucket_url" {
  description = "Media bucket URL"
  value       = module.cloud_storage.media_bucket_url
}

# =============================================================================
# KONG GATEWAY
# =============================================================================

output "kong_loadbalancer_ip" {
  description = "Kong Gateway LoadBalancer IP"
  value       = module.kong.loadbalancer_ip
}

output "kong_admin_url" {
  description = "Kong Admin API URL"
  value       = module.kong.admin_url
}

output "kong_proxy_url" {
  description = "Kong Proxy URL"
  value       = "http://${module.kong.loadbalancer_ip}"
}

# =============================================================================
# KEYCLOAK
# =============================================================================

output "keycloak_loadbalancer_ip" {
  description = "Keycloak LoadBalancer IP"
  value       = module.keycloak.loadbalancer_ip
}

output "keycloak_url" {
  description = "Keycloak URL"
  value       = module.keycloak.keycloak_url
}

output "keycloak_admin_console" {
  description = "Keycloak Admin Console URL"
  value       = "${module.keycloak.keycloak_url}/admin"
}

# =============================================================================
# CLOUD RUN (FRONTEND)
# =============================================================================

output "cloud_run_service_name" {
  description = "Cloud Run service name"
  value       = module.cloud_run.service_name
}

output "cloud_run_url" {
  description = "Cloud Run service URL"
  value       = module.cloud_run.service_url
}

# =============================================================================
# DNS (if enabled)
# =============================================================================

output "dns_name_servers" {
  description = "DNS name servers (configure these at your registrar)"
  value       = var.manage_dns ? module.cloud_dns[0].name_servers : null
}

output "dns_zone_name" {
  description = "DNS zone name"
  value       = var.manage_dns ? module.cloud_dns[0].zone_name : null
}

# =============================================================================
# OBSERVABILITY (if enabled)
# =============================================================================

output "grafana_url" {
  description = "Grafana URL (internal)"
  value       = var.enable_observability ? module.observability[0].grafana_url : null
}

output "prometheus_url" {
  description = "Prometheus URL (internal)"
  value       = var.enable_observability ? module.observability[0].prometheus_url : null
}

# =============================================================================
# ELK STACK (if enabled)
# =============================================================================

output "elasticsearch_url" {
  description = "Elasticsearch URL (internal)"
  value       = var.enable_elk ? module.elk_stack[0].elasticsearch_url : null
}

output "kibana_url" {
  description = "Kibana URL (internal)"
  value       = var.enable_elk ? module.elk_stack[0].kibana_url : null
}

# =============================================================================
# SERVICE URLS SUMMARY
# =============================================================================

output "service_urls" {
  description = "All service URLs"
  value = {
    frontend     = module.cloud_run.service_url
    api_gateway  = "http://${module.kong.loadbalancer_ip}"
    auth         = module.keycloak.keycloak_url
    grafana      = var.enable_observability ? module.observability[0].grafana_url : "disabled"
    kibana       = var.enable_elk ? module.elk_stack[0].kibana_url : "disabled"
  }
}

# =============================================================================
# DEPLOYMENT SUMMARY
# =============================================================================

output "deployment_summary" {
  description = "Deployment summary"
  value = <<-EOT

    ╔═══════════════════════════════════════════════════════════════════╗
    ║                    JOBZY PLATFORM - DEPLOYED                       ║
    ╠═══════════════════════════════════════════════════════════════════╣
    ║                                                                    ║
    ║  Environment: ${var.environment}                                   ║
    ║  Region:      ${var.region}                                        ║
    ║  Project:     ${var.project_id}                                    ║
    ║                                                                    ║
    ║  GKE Cluster: ${module.gke.cluster_name}                           ║
    ║  Nodes:       ${var.gke_num_nodes} (${var.gke_min_nodes}-${var.gke_max_nodes})║
    ║                                                                    ║
    ║  Databases:                                                        ║
    ║    PostgreSQL: ${module.cloud_sql_postgres.private_ip_address}     ║
    ║    MySQL:      ${module.cloud_sql_mysql.private_ip_address}        ║
    ║    Redis:      ${module.redis.host}:${module.redis.port}           ║
    ║                                                                    ║
    ║  Services:                                                         ║
    ║    Kong:     http://${module.kong.loadbalancer_ip}                 ║
    ║    Keycloak: ${module.keycloak.keycloak_url}                       ║
    ║    Frontend: ${module.cloud_run.service_url}                       ║
    ║                                                                    ║
    ╚═══════════════════════════════════════════════════════════════════╝

    Next Steps:
    1. Configure DNS to point to the LoadBalancer IPs above
    2. Access Keycloak Admin: ${module.keycloak.keycloak_url}/admin
    3. Configure Kong routes via Admin API
    4. Deploy your microservices

  EOT
}
