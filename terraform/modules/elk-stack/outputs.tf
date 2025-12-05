# =============================================================================
# ELK Stack Module Outputs
# =============================================================================

output "namespace" {
  description = "Logging namespace"
  value       = kubernetes_namespace.logging.metadata[0].name
}

output "elasticsearch_service" {
  description = "Elasticsearch service name"
  value       = "elasticsearch-master"
}

output "elasticsearch_url" {
  description = "Elasticsearch internal URL"
  value       = "http://elasticsearch-master.${kubernetes_namespace.logging.metadata[0].name}.svc.cluster.local:9200"
}

output "kibana_service" {
  description = "Kibana service name"
  value       = "kibana-kibana"
}

output "kibana_url" {
  description = "Kibana internal URL"
  value       = "http://kibana-kibana.${kubernetes_namespace.logging.metadata[0].name}.svc.cluster.local:5601"
}

output "jaeger_query_service" {
  description = "Jaeger query service name"
  value       = var.enable_jaeger ? "jaeger-query" : null
}

output "jaeger_query_url" {
  description = "Jaeger query internal URL"
  value       = var.enable_jaeger ? "http://jaeger-query.${kubernetes_namespace.logging.metadata[0].name}.svc.cluster.local:16686" : null
}

output "jaeger_collector_endpoint" {
  description = "Jaeger collector endpoint for applications"
  value       = var.enable_jaeger ? "jaeger-collector.${kubernetes_namespace.logging.metadata[0].name}.svc.cluster.local:14268" : null
}
