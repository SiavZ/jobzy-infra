output "namespace" {
  description = "Kong namespace"
  value       = kubernetes_namespace.kong.metadata[0].name
}

output "service_name" {
  description = "Kong proxy service name"
  value       = kubernetes_service.kong_proxy.metadata[0].name
}

output "loadbalancer_ip" {
  description = "Kong LoadBalancer IP (available after deployment)"
  value       = try(kubernetes_service.kong_proxy.status[0].load_balancer[0].ingress[0].ip, "pending")
}

output "admin_service_name" {
  description = "Kong admin service name"
  value       = kubernetes_service.kong_admin.metadata[0].name
}

output "admin_url" {
  description = "Kong Admin API URL (internal)"
  value       = "http://${kubernetes_service.kong_admin.metadata[0].name}.${kubernetes_namespace.kong.metadata[0].name}.svc.cluster.local:8001"
}
