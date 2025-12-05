# =============================================================================
# Cloud DNS Module Outputs
# =============================================================================

output "zone_name" {
  description = "DNS zone name"
  value       = google_dns_managed_zone.public.name
}

output "zone_dns_name" {
  description = "DNS name of the zone"
  value       = google_dns_managed_zone.public.dns_name
}

output "name_servers" {
  description = "Name servers for the zone (configure these at your registrar)"
  value       = google_dns_managed_zone.public.name_servers
}

output "zone_id" {
  description = "Zone ID"
  value       = google_dns_managed_zone.public.id
}

output "private_zone_name" {
  description = "Private DNS zone name"
  value       = var.create_private_zone ? google_dns_managed_zone.private[0].name : null
}

output "private_zone_dns_name" {
  description = "Private DNS zone DNS name"
  value       = var.create_private_zone ? google_dns_managed_zone.private[0].dns_name : null
}

output "dnssec_config" {
  description = "DNSSEC configuration"
  value       = google_dns_managed_zone.public.dnssec_config
}
