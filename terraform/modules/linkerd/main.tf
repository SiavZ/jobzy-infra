# =============================================================================
# Linkerd Service Mesh Module for Jobzy Platform
# =============================================================================
# Deploys Linkerd service mesh for:
# - Automatic mTLS encryption
# - Load balancing
# - Retries and timeouts
# - Circuit breaking
# - Observability (golden metrics)
# =============================================================================

# -----------------------------------------------------------------------------
# Linkerd Namespace
# -----------------------------------------------------------------------------
resource "kubernetes_namespace" "linkerd" {
  metadata {
    name = "linkerd"
    labels = {
      "linkerd.io/control-plane-ns" = "linkerd"
      "linkerd.io/is-control-plane" = "true"
      "config.linkerd.io/admission-webhooks" = "disabled"
    }
    annotations = {
      "linkerd.io/inject" = "disabled"
    }
  }
}

# -----------------------------------------------------------------------------
# Generate Linkerd Trust Anchor Certificate
# -----------------------------------------------------------------------------
resource "tls_private_key" "trust_anchor" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_self_signed_cert" "trust_anchor" {
  private_key_pem = tls_private_key.trust_anchor.private_key_pem

  subject {
    common_name = "root.linkerd.cluster.local"
  }

  validity_period_hours = 87600  # 10 years
  is_ca_certificate     = true

  allowed_uses = [
    "cert_signing",
    "crl_signing",
  ]
}

# -----------------------------------------------------------------------------
# Generate Linkerd Issuer Certificate
# -----------------------------------------------------------------------------
resource "tls_private_key" "issuer" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_cert_request" "issuer" {
  private_key_pem = tls_private_key.issuer.private_key_pem

  subject {
    common_name = "identity.linkerd.cluster.local"
  }
}

resource "tls_locally_signed_cert" "issuer" {
  cert_request_pem   = tls_cert_request.issuer.cert_request_pem
  ca_private_key_pem = tls_private_key.trust_anchor.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.trust_anchor.cert_pem

  validity_period_hours = 8760  # 1 year
  is_ca_certificate     = true

  allowed_uses = [
    "cert_signing",
    "crl_signing",
  ]
}

# -----------------------------------------------------------------------------
# Linkerd CRDs
# -----------------------------------------------------------------------------
resource "helm_release" "linkerd_crds" {
  name       = "linkerd-crds"
  repository = "https://helm.linkerd.io/stable"
  chart      = "linkerd-crds"
  version    = var.linkerd_version
  namespace  = kubernetes_namespace.linkerd.metadata[0].name

  depends_on = [kubernetes_namespace.linkerd]
}

# -----------------------------------------------------------------------------
# Linkerd Control Plane
# -----------------------------------------------------------------------------
resource "helm_release" "linkerd_control_plane" {
  name       = "linkerd-control-plane"
  repository = "https://helm.linkerd.io/stable"
  chart      = "linkerd-control-plane"
  version    = var.linkerd_version
  namespace  = kubernetes_namespace.linkerd.metadata[0].name

  values = [
    yamlencode({
      # Trust anchor certificate
      identityTrustAnchorsPEM = tls_self_signed_cert.trust_anchor.cert_pem

      identity = {
        issuer = {
          tls = {
            crtPEM = tls_locally_signed_cert.issuer.cert_pem
            keyPEM = tls_private_key.issuer.private_key_pem
          }
        }
      }

      # Proxy configuration
      proxy = {
        resources = {
          cpu = {
            request = var.proxy_cpu_request
            limit   = var.proxy_cpu_limit
          }
          memory = {
            request = var.proxy_memory_request
            limit   = var.proxy_memory_limit
          }
        }
      }

      # Control plane resources
      controllerResources = {
        cpu = {
          request = "100m"
          limit   = "1000m"
        }
        memory = {
          request = "50Mi"
          limit   = "250Mi"
        }
      }

      # Destination resources
      destinationResources = {
        cpu = {
          request = "100m"
          limit   = "1000m"
        }
        memory = {
          request = "50Mi"
          limit   = "250Mi"
        }
      }

      # Identity resources
      identityResources = {
        cpu = {
          request = "100m"
          limit   = "1000m"
        }
        memory = {
          request = "50Mi"
          limit   = "250Mi"
        }
      }

      # Proxy injector resources
      proxyInjectorResources = {
        cpu = {
          request = "100m"
          limit   = "1000m"
        }
        memory = {
          request = "50Mi"
          limit   = "250Mi"
        }
      }

      # High availability
      controllerReplicas = var.ha_enabled ? 3 : 1
      enablePodAntiAffinity = var.ha_enabled

      # Prometheus integration
      prometheus = {
        enabled = false  # We use external Prometheus
      }

      # Grafana integration
      grafana = {
        enabled = false  # We use external Grafana
      }
    })
  ]

  depends_on = [helm_release.linkerd_crds]
}

# -----------------------------------------------------------------------------
# Linkerd Viz Extension (Dashboard)
# -----------------------------------------------------------------------------
resource "helm_release" "linkerd_viz" {
  count = var.enable_viz ? 1 : 0

  name       = "linkerd-viz"
  repository = "https://helm.linkerd.io/stable"
  chart      = "linkerd-viz"
  version    = var.linkerd_viz_version
  namespace  = kubernetes_namespace.linkerd.metadata[0].name

  values = [
    yamlencode({
      # Prometheus configuration
      prometheus = {
        enabled = true
      }

      # Dashboard
      dashboard = {
        replicas = var.ha_enabled ? 2 : 1
      }

      # Tap
      tap = {
        replicas = var.ha_enabled ? 2 : 1
      }

      # Web service type
      dashboard = {
        service = {
          type = var.dashboard_service_type
        }
      }

      # Resource limits
      defaultResources = {
        cpu = {
          request = "100m"
          limit   = "500m"
        }
        memory = {
          request = "50Mi"
          limit   = "250Mi"
        }
      }
    })
  ]

  depends_on = [helm_release.linkerd_control_plane]
}

# -----------------------------------------------------------------------------
# Linkerd Jaeger Extension (if enabled)
# -----------------------------------------------------------------------------
resource "helm_release" "linkerd_jaeger" {
  count = var.enable_jaeger ? 1 : 0

  name       = "linkerd-jaeger"
  repository = "https://helm.linkerd.io/stable"
  chart      = "linkerd-jaeger"
  version    = var.linkerd_jaeger_version
  namespace  = kubernetes_namespace.linkerd.metadata[0].name

  values = [
    yamlencode({
      collector = {
        resources = {
          cpu    = "100m"
          memory = "100Mi"
        }
      }

      jaeger = {
        resources = {
          cpu    = "100m"
          memory = "100Mi"
        }
      }

      # Use external Jaeger if available
      webhook = {
        externalSecret = false
        caBundle       = ""
      }
    })
  ]

  depends_on = [helm_release.linkerd_control_plane]
}

# -----------------------------------------------------------------------------
# Namespace Annotations for Auto-Injection
# -----------------------------------------------------------------------------
resource "kubernetes_namespace" "meshed_namespaces" {
  for_each = toset(var.auto_inject_namespaces)

  metadata {
    name = each.key
    annotations = {
      "linkerd.io/inject" = "enabled"
    }
    labels = {
      "linkerd.io/inject" = "enabled"
    }
  }

  depends_on = [helm_release.linkerd_control_plane]
}
