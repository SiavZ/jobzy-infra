# =============================================================================
# Cloud SQL MySQL Module Variables
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

variable "instance_name" {
  description = "Cloud SQL instance name prefix"
  type        = string
}

variable "database_version" {
  description = "MySQL version"
  type        = string
  default     = "MYSQL_8_0"
}

variable "tier" {
  description = "Cloud SQL machine tier"
  type        = string
  default     = "db-custom-2-8192"  # 2 vCPU, 8GB RAM
}

variable "disk_size" {
  description = "Disk size in GB"
  type        = number
  default     = 20
}

variable "availability_type" {
  description = "Availability type (ZONAL or REGIONAL)"
  type        = string
  default     = "ZONAL"
}

variable "max_connections" {
  description = "Maximum number of connections"
  type        = string
  default     = "200"
}

variable "innodb_buffer_pool_size" {
  description = "InnoDB buffer pool size in bytes"
  type        = string
  default     = "5368709120"  # 5GB
}

variable "vpc_network_id" {
  description = "VPC network ID for private IP"
  type        = string
}

variable "private_vpc_connection" {
  description = "Private VPC connection dependency"
  type        = string
}

variable "databases" {
  description = "Map of databases to create"
  type        = map(any)
  default     = {}
}

variable "create_read_replica" {
  description = "Whether to create read replicas"
  type        = bool
  default     = false
}

variable "replica_count" {
  description = "Number of read replicas to create"
  type        = number
  default     = 1
}

variable "replica_tier" {
  description = "Machine tier for read replica (defaults to same as primary)"
  type        = string
  default     = ""
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
