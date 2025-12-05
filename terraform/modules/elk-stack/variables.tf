# =============================================================================
# ELK Stack Module Variables
# =============================================================================

variable "namespace" {
  description = "Kubernetes namespace for logging"
  type        = string
  default     = "logging"
}

variable "elasticsearch_version" {
  description = "Elasticsearch Helm chart version"
  type        = string
  default     = "8.5.1"
}

variable "elasticsearch_replicas" {
  description = "Number of Elasticsearch replicas"
  type        = number
  default     = 3
}

variable "elasticsearch_cpu_request" {
  description = "Elasticsearch CPU request"
  type        = string
  default     = "500m"
}

variable "elasticsearch_cpu_limit" {
  description = "Elasticsearch CPU limit"
  type        = string
  default     = "2000m"
}

variable "elasticsearch_memory_request" {
  description = "Elasticsearch memory request"
  type        = string
  default     = "2Gi"
}

variable "elasticsearch_memory_limit" {
  description = "Elasticsearch memory limit"
  type        = string
  default     = "4Gi"
}

variable "elasticsearch_heap_size" {
  description = "Elasticsearch JVM heap size"
  type        = string
  default     = "2g"
}

variable "elasticsearch_storage_size" {
  description = "Elasticsearch storage size"
  type        = string
  default     = "100Gi"
}

variable "storage_class" {
  description = "Storage class for persistent volumes"
  type        = string
  default     = "standard"
}

variable "kibana_version" {
  description = "Kibana Helm chart version"
  type        = string
  default     = "8.5.1"
}

variable "kibana_service_type" {
  description = "Kibana service type"
  type        = string
  default     = "ClusterIP"
}

variable "kibana_host" {
  description = "Kibana ingress host"
  type        = string
  default     = "kibana.jobzy.fi"
}

variable "filebeat_version" {
  description = "Filebeat Helm chart version"
  type        = string
  default     = "8.5.1"
}

variable "enable_jaeger" {
  description = "Enable Jaeger distributed tracing"
  type        = bool
  default     = true
}

variable "jaeger_version" {
  description = "Jaeger Helm chart version"
  type        = string
  default     = "0.71.0"
}

variable "jaeger_collector_replicas" {
  description = "Number of Jaeger collector replicas"
  type        = number
  default     = 2
}

variable "jaeger_service_type" {
  description = "Jaeger service type"
  type        = string
  default     = "ClusterIP"
}

variable "jaeger_host" {
  description = "Jaeger ingress host"
  type        = string
  default     = "jaeger.jobzy.fi"
}

variable "enable_ingress" {
  description = "Enable ingress for Kibana and Jaeger"
  type        = bool
  default     = false
}

variable "enable_tls" {
  description = "Enable TLS for ingress"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Log retention period in days"
  type        = number
  default     = 30
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
