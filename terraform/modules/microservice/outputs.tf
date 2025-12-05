# =============================================================================
# Microservice Module Outputs
# =============================================================================

output "service_name" {
  description = "Service name"
  value       = kubernetes_deployment.service.metadata[0].name
}

output "namespace" {
  description = "Namespace"
  value       = var.create_namespace ? kubernetes_namespace.service[0].metadata[0].name : var.namespace
}

output "service_account_name" {
  description = "Service account name"
  value       = kubernetes_service_account.service.metadata[0].name
}

output "cluster_ip" {
  description = "Service ClusterIP"
  value       = kubernetes_service.service.spec[0].cluster_ip
}

output "service_dns" {
  description = "Service DNS name"
  value       = "${kubernetes_service.service.metadata[0].name}.${var.create_namespace ? kubernetes_namespace.service[0].metadata[0].name : var.namespace}.svc.cluster.local"
}

output "deployment_name" {
  description = "Deployment name"
  value       = kubernetes_deployment.service.metadata[0].name
}

output "load_balancer_ip" {
  description = "Load balancer IP (if service type is LoadBalancer)"
  value       = var.service_type == "LoadBalancer" ? (length(kubernetes_service.service.status[0].load_balancer[0].ingress) > 0 ? kubernetes_service.service.status[0].load_balancer[0].ingress[0].ip : null) : null
}
