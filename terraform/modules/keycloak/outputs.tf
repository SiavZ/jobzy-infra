output "namespace" {
  description = "Keycloak namespace"
  value       = kubernetes_namespace.keycloak.metadata[0].name
}

output "service_name" {
  description = "Keycloak service name"
  value       = kubernetes_service.keycloak.metadata[0].name
}

output "loadbalancer_ip" {
  description = "Keycloak LoadBalancer IP (available after deployment)"
  value       = try(kubernetes_service.keycloak.status[0].load_balancer[0].ingress[0].ip, "pending")
}

output "keycloak_url" {
  description = "Keycloak URL"
  value       = "http://${var.hostname}"
}

output "admin_console_url" {
  description = "Keycloak Admin Console URL"
  value       = "http://${var.hostname}/admin"
}
