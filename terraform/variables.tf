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
  default     = "n1-standard-2"
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

variable "database_tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-f1-micro"
}

variable "database_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "POSTGRES_15"
}

variable "redis_size_gb" {
  description = "Redis instance size in GB"
  type        = number
  default     = 1
}

variable "kong_replicas" {
  description = "Number of Kong replicas"
  type        = number
  default     = 3
}

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

variable "labels" {
  description = "Common labels for all resources"
  type        = map(string)
  default = {
    "project"    = "jobzy"
    "managed_by" = "terraform"
    "created_at" = "2025-11-26"
  }
}
