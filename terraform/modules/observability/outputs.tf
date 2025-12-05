# =============================================================================
# Observability Module Outputs
# =============================================================================

output "namespace" {
  description = "Monitoring namespace"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "prometheus_service" {
  description = "Prometheus service name"
  value       = "prometheus-stack-prometheus"
}

output "prometheus_url" {
  description = "Prometheus internal URL"
  value       = "http://prometheus-stack-prometheus.${kubernetes_namespace.monitoring.metadata[0].name}.svc.cluster.local:9090"
}

output "grafana_service" {
  description = "Grafana service name"
  value       = "prometheus-stack-grafana"
}

output "grafana_url" {
  description = "Grafana internal URL"
  value       = "http://prometheus-stack-grafana.${kubernetes_namespace.monitoring.metadata[0].name}.svc.cluster.local:80"
}

output "alertmanager_service" {
  description = "AlertManager service name"
  value       = "prometheus-stack-alertmanager"
}

output "alertmanager_url" {
  description = "AlertManager internal URL"
  value       = "http://prometheus-stack-alertmanager.${kubernetes_namespace.monitoring.metadata[0].name}.svc.cluster.local:9093"
}
