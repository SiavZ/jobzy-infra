# =============================================================================
# Linkerd Module Outputs
# =============================================================================

output "namespace" {
  description = "Linkerd namespace"
  value       = kubernetes_namespace.linkerd.metadata[0].name
}

output "trust_anchor_cert" {
  description = "Linkerd trust anchor certificate (PEM)"
  value       = tls_self_signed_cert.trust_anchor.cert_pem
  sensitive   = true
}

output "trust_anchor_expiry" {
  description = "Trust anchor certificate expiry"
  value       = tls_self_signed_cert.trust_anchor.validity_end_time
}

output "issuer_cert_expiry" {
  description = "Issuer certificate expiry"
  value       = tls_locally_signed_cert.issuer.validity_end_time
}

output "viz_dashboard_url" {
  description = "Linkerd Viz dashboard URL (if enabled)"
  value       = var.enable_viz ? "http://linkerd-viz.${kubernetes_namespace.linkerd.metadata[0].name}.svc.cluster.local:8084" : null
}

output "meshed_namespaces" {
  description = "List of namespaces with auto-injection enabled"
  value       = var.auto_inject_namespaces
}
