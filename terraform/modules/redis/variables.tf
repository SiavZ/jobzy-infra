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

variable "instance_name" {
  description = "Redis instance name"
  type        = string
}

variable "size_gb" {
  description = "Redis memory size in GB"
  type        = number
  default     = 1
}

variable "tier" {
  description = "Redis tier (BASIC or STANDARD_HA)"
  type        = string
  default     = "BASIC"
  validation {
    condition     = contains(["BASIC", "STANDARD_HA"], var.tier)
    error_message = "Tier must be BASIC or STANDARD_HA"
  }
}

variable "redis_version" {
  description = "Redis version"
  type        = string
  default     = "7.0"
}

variable "reserved_ip_range" {
  description = "Reserved IP range for Redis instance"
  type        = string
  default     = null
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
