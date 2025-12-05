# =============================================================================
# Cloud DNS Module Variables
# =============================================================================

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "zone_name" {
  description = "DNS zone name (used as resource identifier)"
  type        = string
  default     = "jobzy"
}

variable "domain" {
  description = "Domain name (e.g., jobzy.fi)"
  type        = string
}

variable "enable_dnssec" {
  description = "Enable DNSSEC for the zone"
  type        = bool
  default     = true
}

variable "frontend_ip" {
  description = "IP address for frontend (Cloud Run)"
  type        = string
  default     = ""
}

variable "kong_ip" {
  description = "IP address for Kong API Gateway"
  type        = string
  default     = ""
}

variable "keycloak_ip" {
  description = "IP address for Keycloak"
  type        = string
  default     = ""
}

variable "services_ip" {
  description = "IP address for other services (shared load balancer)"
  type        = string
  default     = ""
}

variable "monitoring_ip" {
  description = "IP address for monitoring services"
  type        = string
  default     = ""
}

variable "enable_service_subdomains" {
  description = "Create DNS records for service subdomains"
  type        = bool
  default     = false
}

variable "enable_monitoring_subdomains" {
  description = "Create DNS records for monitoring subdomains"
  type        = bool
  default     = false
}

variable "mx_records" {
  description = "MX records for email"
  type        = list(string)
  default     = []
}

variable "txt_records" {
  description = "TXT records (SPF, verification, etc.)"
  type        = list(string)
  default     = []
}

variable "create_private_zone" {
  description = "Create a private DNS zone for internal services"
  type        = bool
  default     = false
}

variable "vpc_network_id" {
  description = "VPC network ID for private DNS zone"
  type        = string
  default     = ""
}

variable "internal_services" {
  description = "Map of internal service names to IP addresses"
  type        = map(string)
  default     = {}
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
