# =============================================================================
# Microservice Module Variables
# =============================================================================

# Basic configuration
variable "service_name" {
  description = "Name of the microservice"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
}

variable "create_namespace" {
  description = "Create the namespace if it doesn't exist"
  type        = bool
  default     = false
}

# Container image
variable "image_repository" {
  description = "Container image repository"
  type        = string
}

variable "image_tag" {
  description = "Container image tag"
  type        = string
  default     = "latest"
}

variable "image_pull_policy" {
  description = "Image pull policy"
  type        = string
  default     = "IfNotPresent"
}

variable "image_pull_secrets" {
  description = "Image pull secrets"
  type        = list(string)
  default     = []
}

# Scaling
variable "replicas" {
  description = "Number of replicas"
  type        = number
  default     = 1
}

variable "max_surge" {
  description = "Maximum surge during rolling update"
  type        = string
  default     = "25%"
}

variable "max_unavailable" {
  description = "Maximum unavailable during rolling update"
  type        = string
  default     = "25%"
}

# Resources
variable "cpu_request" {
  description = "CPU request"
  type        = string
  default     = "100m"
}

variable "cpu_limit" {
  description = "CPU limit"
  type        = string
  default     = "500m"
}

variable "memory_request" {
  description = "Memory request"
  type        = string
  default     = "256Mi"
}

variable "memory_limit" {
  description = "Memory limit"
  type        = string
  default     = "512Mi"
}

# Networking
variable "ports" {
  description = "Container ports"
  type = list(object({
    name           = string
    container_port = number
    service_port   = number
    protocol       = optional(string, "TCP")
  }))
  default = []
}

variable "service_type" {
  description = "Kubernetes service type"
  type        = string
  default     = "ClusterIP"
}

variable "service_annotations" {
  description = "Service annotations"
  type        = map(string)
  default     = {}
}

# Environment
variable "environment_variables" {
  description = "Environment variables"
  type        = map(string)
  default     = {}
}

variable "config_data" {
  description = "ConfigMap data"
  type        = map(string)
  default     = {}
}

variable "secret_data" {
  description = "Secret data"
  type        = map(string)
  default     = {}
  sensitive   = true
}

# Health checks
variable "liveness_probe_path" {
  description = "Liveness probe HTTP path"
  type        = string
  default     = "/health"
}

variable "readiness_probe_path" {
  description = "Readiness probe HTTP path"
  type        = string
  default     = "/ready"
}

variable "health_check_port" {
  description = "Health check port"
  type        = number
  default     = 8080
}

variable "liveness_initial_delay" {
  description = "Liveness probe initial delay"
  type        = number
  default     = 30
}

variable "liveness_period" {
  description = "Liveness probe period"
  type        = number
  default     = 10
}

variable "liveness_timeout" {
  description = "Liveness probe timeout"
  type        = number
  default     = 5
}

variable "liveness_failure_threshold" {
  description = "Liveness probe failure threshold"
  type        = number
  default     = 3
}

variable "readiness_initial_delay" {
  description = "Readiness probe initial delay"
  type        = number
  default     = 10
}

variable "readiness_period" {
  description = "Readiness probe period"
  type        = number
  default     = 5
}

variable "readiness_timeout" {
  description = "Readiness probe timeout"
  type        = number
  default     = 3
}

variable "readiness_failure_threshold" {
  description = "Readiness probe failure threshold"
  type        = number
  default     = 3
}

# Monitoring
variable "enable_prometheus" {
  description = "Enable Prometheus scraping"
  type        = bool
  default     = true
}

variable "metrics_port" {
  description = "Prometheus metrics port"
  type        = number
  default     = 8080
}

variable "metrics_path" {
  description = "Prometheus metrics path"
  type        = string
  default     = "/metrics"
}

# HPA
variable "enable_hpa" {
  description = "Enable Horizontal Pod Autoscaler"
  type        = bool
  default     = false
}

variable "hpa_min_replicas" {
  description = "HPA minimum replicas"
  type        = number
  default     = 1
}

variable "hpa_max_replicas" {
  description = "HPA maximum replicas"
  type        = number
  default     = 5
}

variable "hpa_cpu_target" {
  description = "HPA CPU target utilization"
  type        = number
  default     = 70
}

variable "hpa_memory_target" {
  description = "HPA memory target utilization"
  type        = number
  default     = 80
}

# PDB
variable "enable_pdb" {
  description = "Enable Pod Disruption Budget"
  type        = bool
  default     = false
}

variable "pdb_min_available" {
  description = "PDB minimum available pods"
  type        = string
  default     = "1"
}

# Service Mesh
variable "enable_linkerd" {
  description = "Enable Linkerd sidecar injection"
  type        = bool
  default     = true
}

# Security
variable "run_as_non_root" {
  description = "Run as non-root user"
  type        = bool
  default     = true
}

variable "run_as_user" {
  description = "Run as user ID"
  type        = number
  default     = 1000
}

variable "fs_group" {
  description = "Filesystem group ID"
  type        = number
  default     = 1000
}

variable "gcp_service_account" {
  description = "GCP service account for Workload Identity"
  type        = string
  default     = ""
}

# Volumes
variable "volumes" {
  description = "Volumes configuration"
  type        = list(any)
  default     = []
}

variable "volume_mounts" {
  description = "Volume mounts configuration"
  type        = list(any)
  default     = []
}

# Node scheduling
variable "node_selector" {
  description = "Node selector"
  type        = map(string)
  default     = {}
}

variable "tolerations" {
  description = "Pod tolerations"
  type        = list(any)
  default     = []
}

variable "pod_annotations" {
  description = "Additional pod annotations"
  type        = map(string)
  default     = {}
}

# Labels
variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
