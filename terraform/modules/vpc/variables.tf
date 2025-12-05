# =============================================================================
# VPC Module Variables
# =============================================================================

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

variable "network_name" {
  description = "VPC network name prefix"
  type        = string
}

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

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
