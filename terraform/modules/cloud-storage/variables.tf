# =============================================================================
# Cloud Storage Module Variables
# =============================================================================

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "location" {
  description = "GCS bucket location (region or multi-region)"
  type        = string
  default     = "europe-north1"
}

variable "storage_class" {
  description = "Default storage class for buckets"
  type        = string
  default     = "STANDARD"
  validation {
    condition     = contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"], var.storage_class)
    error_message = "Storage class must be STANDARD, NEARLINE, COLDLINE, or ARCHIVE"
  }
}

variable "cors_origins" {
  description = "Allowed CORS origins"
  type        = list(string)
  default     = ["https://jobzy.fi", "https://www.jobzy.fi"]
}

variable "gke_service_account" {
  description = "GKE service account email for IAM bindings"
  type        = string
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
