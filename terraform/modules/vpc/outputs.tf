# =============================================================================
# VPC Module Outputs
# =============================================================================

output "network_name" {
  description = "VPC network name"
  value       = google_compute_network.vpc.name
}

output "network_id" {
  description = "VPC network ID"
  value       = google_compute_network.vpc.id
}

output "network_self_link" {
  description = "VPC network self link"
  value       = google_compute_network.vpc.self_link
}

output "gke_subnet_name" {
  description = "GKE subnet name"
  value       = google_compute_subnetwork.gke_subnet.name
}

output "gke_subnet_id" {
  description = "GKE subnet ID"
  value       = google_compute_subnetwork.gke_subnet.id
}

output "gke_subnet_self_link" {
  description = "GKE subnet self link"
  value       = google_compute_subnetwork.gke_subnet.self_link
}

output "services_subnet_name" {
  description = "Services subnet name"
  value       = google_compute_subnetwork.services_subnet.name
}

output "services_subnet_id" {
  description = "Services subnet ID"
  value       = google_compute_subnetwork.services_subnet.id
}

output "gke_pods_range_name" {
  description = "GKE pods secondary range name"
  value       = "gke-pods"
}

output "gke_services_range_name" {
  description = "GKE services secondary range name"
  value       = "gke-services"
}

output "router_name" {
  description = "Cloud Router name"
  value       = google_compute_router.router.name
}

output "nat_name" {
  description = "Cloud NAT name"
  value       = google_compute_router_nat.nat.name
}

output "private_vpc_connection" {
  description = "Private VPC connection for Cloud SQL"
  value       = google_service_networking_connection.private_vpc_connection.id
}

output "private_ip_range_name" {
  description = "Private IP range name for service networking"
  value       = google_compute_global_address.private_ip_range.name
}
