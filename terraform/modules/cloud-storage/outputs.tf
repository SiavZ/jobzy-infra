# =============================================================================
# Cloud Storage Module Outputs
# =============================================================================

output "media_bucket_name" {
  description = "Media bucket name"
  value       = google_storage_bucket.media.name
}

output "media_bucket_url" {
  description = "Media bucket URL"
  value       = google_storage_bucket.media.url
}

output "media_bucket_self_link" {
  description = "Media bucket self link"
  value       = google_storage_bucket.media.self_link
}

output "documents_bucket_name" {
  description = "Documents bucket name"
  value       = google_storage_bucket.documents.name
}

output "documents_bucket_url" {
  description = "Documents bucket URL"
  value       = google_storage_bucket.documents.url
}

output "backups_bucket_name" {
  description = "Backups bucket name"
  value       = google_storage_bucket.backups.name
}

output "backups_bucket_url" {
  description = "Backups bucket URL"
  value       = google_storage_bucket.backups.url
}

output "temp_bucket_name" {
  description = "Temporary bucket name"
  value       = google_storage_bucket.temp.name
}

output "temp_bucket_url" {
  description = "Temporary bucket URL"
  value       = google_storage_bucket.temp.url
}

output "all_bucket_names" {
  description = "All bucket names"
  value = {
    media     = google_storage_bucket.media.name
    documents = google_storage_bucket.documents.name
    backups   = google_storage_bucket.backups.name
    temp      = google_storage_bucket.temp.name
  }
}
