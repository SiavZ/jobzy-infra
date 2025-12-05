# =============================================================================
# Jobzy Platform - Terraform Variables
# =============================================================================

# =============================================================================
# PROJECT & ENVIRONMENT
# =============================================================================

variable "project_id" {
  description = "GCP Project ID"
  type        = string
  validation {
    condition     = length(var.project_id) > 0
    error_message = "Project ID cannot be empty"
  }
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "europe-north1"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod"
  }
}

variable "domain" {
  description = "Primary domain name"
  type        = string
  default     = "jobzy.fi"
}

# =============================================================================
# NETWORKING
# =============================================================================

variable "gke_subnet_cidr" {
  description = "CIDR range for GKE subnet"
  type        = string
  default     = "10.0.0.0/20"
}

variable "gke_pods_cidr" {
  description = "Secondary CIDR range for GKE pods"
  type        = string
  default     = "10.48.0.0/14"
}

variable "gke_services_cidr" {
  description = "Secondary CIDR range for GKE services"
  type        = string
  default     = "10.52.0.0/20"
}

variable "services_subnet_cidr" {
  description = "CIDR range for Cloud SQL and other services"
  type        = string
  default     = "10.1.0.0/20"
}

# =============================================================================
# GKE CLUSTER
# =============================================================================

variable "cluster_name" {
  description = "GKE Cluster name"
  type        = string
}

variable "gke_num_nodes" {
  description = "Initial number of GKE nodes"
  type        = number
  default     = 3
  validation {
    condition     = var.gke_num_nodes >= 1 && var.gke_num_nodes <= 100
    error_message = "Node count must be between 1 and 100"
  }
}

variable "gke_machine_type" {
  description = "GKE node machine type"
  type        = string
  default     = "n1-standard-4"
}

variable "gke_min_nodes" {
  description = "Minimum number of nodes for autoscaling"
  type        = number
  default     = 2
}

variable "gke_max_nodes" {
  description = "Maximum number of nodes for autoscaling"
  type        = number
  default     = 10
}

# =============================================================================
# CLOUD SQL - POSTGRESQL
# =============================================================================

variable "postgres_tier" {
  description = "Cloud SQL PostgreSQL tier"
  type        = string
  default     = "db-custom-4-16384"  # 4 vCPU, 16GB RAM
}

variable "postgres_disk_size" {
  description = "PostgreSQL disk size in GB"
  type        = number
  default     = 100
}

variable "postgres_max_connections" {
  description = "PostgreSQL max connections"
  type        = string
  default     = "500"
}

# =============================================================================
# CLOUD SQL - MYSQL
# =============================================================================

variable "mysql_tier" {
  description = "Cloud SQL MySQL tier"
  type        = string
  default     = "db-custom-4-16384"  # 4 vCPU, 16GB RAM
}

variable "mysql_disk_size" {
  description = "MySQL disk size in GB"
  type        = number
  default     = 200
}

variable "mysql_max_connections" {
  description = "MySQL max connections"
  type        = string
  default     = "500"
}

# =============================================================================
# REDIS
# =============================================================================

variable "redis_size_gb" {
  description = "Redis instance size in GB"
  type        = number
  default     = 4
}

# =============================================================================
# KONG GATEWAY
# =============================================================================

variable "kong_replicas" {
  description = "Number of Kong replicas"
  type        = number
  default     = 3
}

# =============================================================================
# KEYCLOAK
# =============================================================================

variable "keycloak_replicas" {
  description = "Number of Keycloak replicas"
  type        = number
  default     = 2
}

variable "keycloak_admin_password" {
  description = "Keycloak admin password"
  type        = string
  sensitive   = true
}

variable "keycloak_hostname" {
  description = "Keycloak hostname"
  type        = string
  default     = "auth.jobzy.fi"
}

# =============================================================================
# CLOUD RUN (FRONTEND)
# =============================================================================

variable "frontend_image" {
  description = "Frontend container image"
  type        = string
  default     = "gcr.io/cloudrun/placeholder"
}

variable "frontend_max_instances" {
  description = "Maximum frontend instances"
  type        = number
  default     = 10
}

variable "frontend_domain" {
  description = "Frontend custom domain"
  type        = string
  default     = ""
}

variable "cors_origins" {
  description = "Allowed CORS origins"
  type        = list(string)
  default     = ["https://jobzy.fi", "https://www.jobzy.fi"]
}

# =============================================================================
# OBSERVABILITY
# =============================================================================

variable "enable_observability" {
  description = "Enable Prometheus + Grafana stack"
  type        = bool
  default     = true
}

variable "prometheus_retention" {
  description = "Prometheus data retention"
  type        = string
  default     = "15d"
}

variable "prometheus_storage_size" {
  description = "Prometheus storage size"
  type        = string
  default     = "50Gi"
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for alerts"
  type        = string
  sensitive   = true
  default     = ""
}

variable "slack_channel" {
  description = "Slack channel for alerts"
  type        = string
  default     = "#alerts"
}

variable "pagerduty_service_key" {
  description = "PagerDuty service key"
  type        = string
  sensitive   = true
  default     = ""
}

# =============================================================================
# ELK STACK
# =============================================================================

variable "enable_elk" {
  description = "Enable ELK logging stack"
  type        = bool
  default     = true
}

variable "elasticsearch_storage_size" {
  description = "Elasticsearch storage size"
  type        = string
  default     = "100Gi"
}

variable "enable_jaeger" {
  description = "Enable Jaeger distributed tracing"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 30
}

# =============================================================================
# SERVICE MESH
# =============================================================================

variable "enable_linkerd" {
  description = "Enable Linkerd service mesh"
  type        = bool
  default     = true
}

variable "linkerd_version" {
  description = "Linkerd version"
  type        = string
  default     = "1.16.0"
}

# =============================================================================
# DNS
# =============================================================================

variable "manage_dns" {
  description = "Manage DNS via Terraform"
  type        = bool
  default     = false
}

variable "enable_service_subdomains" {
  description = "Enable service subdomains (crm, chat, etc.)"
  type        = bool
  default     = false
}

variable "enable_monitoring_subdomains" {
  description = "Enable monitoring subdomains (grafana, kibana)"
  type        = bool
  default     = false
}

# =============================================================================
# LABELS
# =============================================================================

variable "labels" {
  description = "Common labels for all resources"
  type        = map(string)
  default = {
    "project"    = "jobzy"
    "managed_by" = "terraform"
  }
}
