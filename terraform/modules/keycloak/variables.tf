variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "cluster_name" {
  description = "GKE Cluster name"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for Keycloak"
  type        = string
  default     = "keycloak"
}

variable "replicas" {
  description = "Number of Keycloak replicas"
  type        = number
  default     = 2
}

variable "keycloak_version" {
  description = "Keycloak Docker image version"
  type        = string
  default     = "23.0"
}

variable "db_host" {
  description = "PostgreSQL host"
  type        = string
}

variable "db_port" {
  description = "PostgreSQL port"
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "keycloak"
}

variable "db_user" {
  description = "PostgreSQL username"
  type        = string
}

variable "db_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}

variable "redis_host" {
  description = "Redis host (for session caching)"
  type        = string
}

variable "redis_port" {
  description = "Redis port"
  type        = number
  default     = 6379
}

variable "admin_password" {
  description = "Keycloak admin password"
  type        = string
  sensitive   = true
}

variable "hostname" {
  description = "Keycloak hostname"
  type        = string
  default     = "auth.jobzy.fi"
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
