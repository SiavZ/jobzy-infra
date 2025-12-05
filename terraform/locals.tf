# =============================================================================
# Jobzy Platform - Local Variables
# =============================================================================

locals {
  # Resource naming prefix
  resource_prefix = "jobzy-${var.environment}"

  # Common labels for all resources
  common_labels = merge(
    var.labels,
    {
      "environment" = var.environment
      "cluster"     = var.cluster_name
    }
  )

  # Namespace definitions
  kong_namespace       = "kong-system"
  keycloak_namespace   = "keycloak"
  monitoring_namespace = "monitoring"
  logging_namespace    = "logging"
  jobzy_namespace      = "jobzy"

  # All namespaces for monitoring
  all_namespaces = [
    "default",
    local.kong_namespace,
    local.keycloak_namespace,
    local.monitoring_namespace,
    local.logging_namespace,
    local.jobzy_namespace
  ]

  # Namespaces for service mesh injection
  mesh_namespaces = [
    local.kong_namespace,
    local.keycloak_namespace,
    local.jobzy_namespace
  ]

  # Database naming
  database_name = "jobzy_${replace(var.environment, "-", "_")}"

  # Environment-specific configurations
  env_config = {
    dev = {
      gke_node_count     = 2
      gke_max_nodes      = 5
      db_tier            = "db-custom-2-8192"
      redis_size_gb      = 1
      kong_replicas      = 1
      keycloak_replicas  = 1
      use_preemptible    = true
      enable_ha          = false
    }
    staging = {
      gke_node_count     = 3
      gke_max_nodes      = 8
      db_tier            = "db-custom-4-16384"
      redis_size_gb      = 4
      kong_replicas      = 2
      keycloak_replicas  = 2
      use_preemptible    = true
      enable_ha          = false
    }
    prod = {
      gke_node_count     = 3
      gke_max_nodes      = 20
      db_tier            = "db-custom-8-32768"
      redis_size_gb      = 16
      kong_replicas      = 3
      keycloak_replicas  = 2
      use_preemptible    = false
      enable_ha          = true
    }
  }

  # Current environment config
  current_env_config = local.env_config[var.environment]

  # Service URLs
  service_urls = {
    api_url      = "https://api.${var.domain}"
    auth_url     = "https://auth.${var.domain}"
    frontend_url = "https://${var.domain}"
    grafana_url  = "https://grafana.${var.domain}"
    kibana_url   = "https://kibana.${var.domain}"
  }
}
