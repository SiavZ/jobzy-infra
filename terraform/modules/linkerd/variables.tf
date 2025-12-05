# =============================================================================
# Linkerd Module Variables
# =============================================================================

variable "linkerd_version" {
  description = "Linkerd Helm chart version"
  type        = string
  default     = "1.16.0"
}

variable "linkerd_viz_version" {
  description = "Linkerd Viz extension version"
  type        = string
  default     = "30.12.0"
}

variable "linkerd_jaeger_version" {
  description = "Linkerd Jaeger extension version"
  type        = string
  default     = "30.12.0"
}

variable "ha_enabled" {
  description = "Enable high availability mode"
  type        = bool
  default     = false
}

variable "enable_viz" {
  description = "Enable Linkerd Viz dashboard"
  type        = bool
  default     = true
}

variable "enable_jaeger" {
  description = "Enable Linkerd Jaeger extension"
  type        = bool
  default     = false
}

variable "proxy_cpu_request" {
  description = "CPU request for Linkerd proxy sidecar"
  type        = string
  default     = "10m"
}

variable "proxy_cpu_limit" {
  description = "CPU limit for Linkerd proxy sidecar"
  type        = string
  default     = "1000m"
}

variable "proxy_memory_request" {
  description = "Memory request for Linkerd proxy sidecar"
  type        = string
  default     = "20Mi"
}

variable "proxy_memory_limit" {
  description = "Memory limit for Linkerd proxy sidecar"
  type        = string
  default     = "250Mi"
}

variable "dashboard_service_type" {
  description = "Service type for Linkerd dashboard"
  type        = string
  default     = "ClusterIP"
}

variable "auto_inject_namespaces" {
  description = "List of namespaces to enable auto-injection"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
