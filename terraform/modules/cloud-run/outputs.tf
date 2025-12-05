# =============================================================================
# Cloud Run Module Outputs
# =============================================================================

output "service_name" {
  description = "Cloud Run service name"
  value       = google_cloud_run_v2_service.frontend.name
}

output "service_url" {
  description = "Cloud Run service URL"
  value       = google_cloud_run_v2_service.frontend.uri
}

output "service_id" {
  description = "Cloud Run service ID"
  value       = google_cloud_run_v2_service.frontend.id
}

output "latest_revision" {
  description = "Latest revision name"
  value       = google_cloud_run_v2_service.frontend.latest_ready_revision
}

output "vpc_connector_name" {
  description = "VPC connector name"
  value       = google_vpc_access_connector.connector.name
}

output "vpc_connector_id" {
  description = "VPC connector ID"
  value       = google_vpc_access_connector.connector.id
}

output "custom_domain_status" {
  description = "Custom domain mapping status"
  value       = var.custom_domain != "" ? google_cloud_run_domain_mapping.primary[0].status : null
}
