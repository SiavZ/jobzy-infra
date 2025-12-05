# =============================================================================
# Cloud Storage (GCS) Module for Jobzy Platform
# =============================================================================
# Creates storage buckets for:
# - Media files (provider pics, service photos)
# - Documents (invoices, receipts, contracts)
# - Backups and archives
# - Terraform state (if not already created)
# =============================================================================

# -----------------------------------------------------------------------------
# Main Storage Bucket - Media and Files
# -----------------------------------------------------------------------------
resource "google_storage_bucket" "media" {
  name          = "${var.project_id}-${var.environment}-media"
  location      = var.location
  storage_class = var.storage_class
  project       = var.project_id

  # Enable versioning for data protection
  versioning {
    enabled = true
  }

  # Lifecycle rules for cost optimization
  lifecycle_rule {
    condition {
      age = 30
      matches_storage_class = ["STANDARD"]
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 90
      matches_storage_class = ["NEARLINE"]
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 365
      matches_storage_class = ["COLDLINE"]
    }
    action {
      type          = "SetStorageClass"
      storage_class = "ARCHIVE"
    }
  }

  # Delete old versions after 30 days
  lifecycle_rule {
    condition {
      num_newer_versions = 3
      with_state         = "ARCHIVED"
    }
    action {
      type = "Delete"
    }
  }

  # Uniform bucket-level access
  uniform_bucket_level_access = true

  # CORS configuration for frontend access
  cors {
    origin          = var.cors_origins
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["Content-Type", "Content-Length", "Content-MD5", "x-goog-meta-*"]
    max_age_seconds = 3600
  }

  # Encryption with Google-managed key (default)
  # For customer-managed keys, add encryption block

  labels = var.labels

  force_destroy = var.environment != "prod"
}

# -----------------------------------------------------------------------------
# Documents Bucket - Invoices, Receipts, Contracts
# -----------------------------------------------------------------------------
resource "google_storage_bucket" "documents" {
  name          = "${var.project_id}-${var.environment}-documents"
  location      = var.location
  storage_class = var.storage_class
  project       = var.project_id

  versioning {
    enabled = true
  }

  # Legal compliance - 7 year retention
  lifecycle_rule {
    condition {
      age = 30
      matches_storage_class = ["STANDARD"]
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 365
      matches_storage_class = ["NEARLINE"]
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  # Keep documents for 7 years (legal requirement)
  lifecycle_rule {
    condition {
      age = 2555  # 7 years
    }
    action {
      type = "Delete"
    }
  }

  uniform_bucket_level_access = true

  # CORS for signed URL uploads
  cors {
    origin          = var.cors_origins
    method          = ["GET", "HEAD", "PUT", "POST"]
    response_header = ["Content-Type", "Content-Length"]
    max_age_seconds = 3600
  }

  labels = var.labels

  force_destroy = var.environment != "prod"
}

# -----------------------------------------------------------------------------
# Backups Bucket - Database backups and archives
# -----------------------------------------------------------------------------
resource "google_storage_bucket" "backups" {
  name          = "${var.project_id}-${var.environment}-backups"
  location      = var.location
  storage_class = "NEARLINE"  # Backups accessed less frequently
  project       = var.project_id

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type          = "SetStorageClass"
      storage_class = "ARCHIVE"
    }
  }

  # Keep backups for 2 years
  lifecycle_rule {
    condition {
      age = 730
    }
    action {
      type = "Delete"
    }
  }

  uniform_bucket_level_access = true

  labels = var.labels

  force_destroy = var.environment != "prod"
}

# -----------------------------------------------------------------------------
# Temporary Bucket - Upload staging, processing
# -----------------------------------------------------------------------------
resource "google_storage_bucket" "temp" {
  name          = "${var.project_id}-${var.environment}-temp"
  location      = var.location
  storage_class = "STANDARD"
  project       = var.project_id

  versioning {
    enabled = false  # No versioning for temp files
  }

  # Auto-delete after 1 day
  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "Delete"
    }
  }

  uniform_bucket_level_access = true

  cors {
    origin          = var.cors_origins
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["Content-Type", "Content-Length"]
    max_age_seconds = 3600
  }

  labels = var.labels

  force_destroy = true  # Always allow destroy for temp bucket
}

# -----------------------------------------------------------------------------
# IAM Bindings for Service Accounts
# -----------------------------------------------------------------------------

# Media bucket - read for all services, write for specific services
resource "google_storage_bucket_iam_member" "media_viewer" {
  bucket = google_storage_bucket.media.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${var.gke_service_account}"
}

resource "google_storage_bucket_iam_member" "media_creator" {
  bucket = google_storage_bucket.media.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${var.gke_service_account}"
}

# Documents bucket - restricted access
resource "google_storage_bucket_iam_member" "documents_admin" {
  bucket = google_storage_bucket.documents.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.gke_service_account}"
}

# Backups bucket - admin access for backup jobs
resource "google_storage_bucket_iam_member" "backups_admin" {
  bucket = google_storage_bucket.backups.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.gke_service_account}"
}

# Temp bucket - full access for all services
resource "google_storage_bucket_iam_member" "temp_admin" {
  bucket = google_storage_bucket.temp.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.gke_service_account}"
}
