# =============================================================================
# Cloud DNS Module for Jobzy Platform
# =============================================================================
# Manages DNS zones and records for:
# - jobzy.fi (main domain)
# - api.jobzy.fi (API Gateway/Kong)
# - auth.jobzy.fi (Keycloak)
# - Various service subdomains
# =============================================================================

# -----------------------------------------------------------------------------
# Public DNS Zone
# -----------------------------------------------------------------------------
resource "google_dns_managed_zone" "public" {
  name        = "${var.zone_name}-public"
  dns_name    = "${var.domain}."
  description = "Public DNS zone for ${var.domain}"
  project     = var.project_id

  visibility = "public"

  dnssec_config {
    state = var.enable_dnssec ? "on" : "off"
  }

  labels = var.labels
}

# -----------------------------------------------------------------------------
# A Records
# -----------------------------------------------------------------------------

# Main domain -> Cloud Run
resource "google_dns_record_set" "root" {
  count = var.frontend_ip != "" ? 1 : 0

  name         = google_dns_managed_zone.public.dns_name
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.public.name
  project      = var.project_id

  rrdatas = [var.frontend_ip]
}

# www subdomain -> Cloud Run
resource "google_dns_record_set" "www" {
  count = var.frontend_ip != "" ? 1 : 0

  name         = "www.${google_dns_managed_zone.public.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.public.name
  project      = var.project_id

  rrdatas = [var.frontend_ip]
}

# API subdomain -> Kong Gateway
resource "google_dns_record_set" "api" {
  count = var.kong_ip != "" ? 1 : 0

  name         = "api.${google_dns_managed_zone.public.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.public.name
  project      = var.project_id

  rrdatas = [var.kong_ip]
}

# Auth subdomain -> Keycloak
resource "google_dns_record_set" "auth" {
  count = var.keycloak_ip != "" ? 1 : 0

  name         = "auth.${google_dns_managed_zone.public.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.public.name
  project      = var.project_id

  rrdatas = [var.keycloak_ip]
}

# -----------------------------------------------------------------------------
# Service Subdomains (optional)
# -----------------------------------------------------------------------------

# CRM subdomain -> SuiteCRM
resource "google_dns_record_set" "crm" {
  count = var.services_ip != "" && var.enable_service_subdomains ? 1 : 0

  name         = "crm.${google_dns_managed_zone.public.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.public.name
  project      = var.project_id

  rrdatas = [var.services_ip]
}

# Chat subdomain -> Chatwoot
resource "google_dns_record_set" "chat" {
  count = var.services_ip != "" && var.enable_service_subdomains ? 1 : 0

  name         = "chat.${google_dns_managed_zone.public.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.public.name
  project      = var.project_id

  rrdatas = [var.services_ip]
}

# Calendar subdomain -> EasyAppointments
resource "google_dns_record_set" "calendar" {
  count = var.services_ip != "" && var.enable_service_subdomains ? 1 : 0

  name         = "calendar.${google_dns_managed_zone.public.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.public.name
  project      = var.project_id

  rrdatas = [var.services_ip]
}

# CMS subdomain -> Strapi
resource "google_dns_record_set" "cms" {
  count = var.services_ip != "" && var.enable_service_subdomains ? 1 : 0

  name         = "cms.${google_dns_managed_zone.public.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.public.name
  project      = var.project_id

  rrdatas = [var.services_ip]
}

# Grafana subdomain -> Monitoring
resource "google_dns_record_set" "grafana" {
  count = var.monitoring_ip != "" && var.enable_monitoring_subdomains ? 1 : 0

  name         = "grafana.${google_dns_managed_zone.public.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.public.name
  project      = var.project_id

  rrdatas = [var.monitoring_ip]
}

# Kibana subdomain -> Logging
resource "google_dns_record_set" "kibana" {
  count = var.monitoring_ip != "" && var.enable_monitoring_subdomains ? 1 : 0

  name         = "kibana.${google_dns_managed_zone.public.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.public.name
  project      = var.project_id

  rrdatas = [var.monitoring_ip]
}

# -----------------------------------------------------------------------------
# MX Records (Email)
# -----------------------------------------------------------------------------
resource "google_dns_record_set" "mx" {
  count = length(var.mx_records) > 0 ? 1 : 0

  name         = google_dns_managed_zone.public.dns_name
  type         = "MX"
  ttl          = 3600
  managed_zone = google_dns_managed_zone.public.name
  project      = var.project_id

  rrdatas = var.mx_records
}

# -----------------------------------------------------------------------------
# TXT Records (SPF, DKIM, etc.)
# -----------------------------------------------------------------------------
resource "google_dns_record_set" "txt" {
  count = length(var.txt_records) > 0 ? 1 : 0

  name         = google_dns_managed_zone.public.dns_name
  type         = "TXT"
  ttl          = 3600
  managed_zone = google_dns_managed_zone.public.name
  project      = var.project_id

  rrdatas = var.txt_records
}

# -----------------------------------------------------------------------------
# CAA Records (Certificate Authority Authorization)
# -----------------------------------------------------------------------------
resource "google_dns_record_set" "caa" {
  name         = google_dns_managed_zone.public.dns_name
  type         = "CAA"
  ttl          = 3600
  managed_zone = google_dns_managed_zone.public.name
  project      = var.project_id

  rrdatas = [
    "0 issue \"letsencrypt.org\"",
    "0 issue \"pki.goog\"",
    "0 issuewild \"letsencrypt.org\"",
    "0 issuewild \"pki.goog\""
  ]
}

# -----------------------------------------------------------------------------
# Private DNS Zone (Internal)
# -----------------------------------------------------------------------------
resource "google_dns_managed_zone" "private" {
  count = var.create_private_zone ? 1 : 0

  name        = "${var.zone_name}-private"
  dns_name    = "internal.${var.domain}."
  description = "Private DNS zone for internal services"
  project     = var.project_id

  visibility = "private"

  private_visibility_config {
    networks {
      network_url = var.vpc_network_id
    }
  }

  labels = var.labels
}

# Internal service records
resource "google_dns_record_set" "internal_services" {
  for_each = var.create_private_zone ? var.internal_services : {}

  name         = "${each.key}.internal.${var.domain}."
  type         = "A"
  ttl          = 60
  managed_zone = google_dns_managed_zone.private[0].name
  project      = var.project_id

  rrdatas = [each.value]
}
