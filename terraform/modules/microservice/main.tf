# =============================================================================
# Generic Microservice Deployment Module for Jobzy Platform
# =============================================================================
# Deploys a containerized microservice to Kubernetes with:
# - Deployment with configurable replicas
# - Service (ClusterIP or LoadBalancer)
# - ConfigMap and Secrets
# - HorizontalPodAutoscaler
# - PodDisruptionBudget
# - ServiceAccount with Workload Identity
# =============================================================================

# -----------------------------------------------------------------------------
# Namespace (create if specified)
# -----------------------------------------------------------------------------
resource "kubernetes_namespace" "service" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace
    labels = merge(
      var.labels,
      {
        "name"              = var.namespace
        "linkerd.io/inject" = var.enable_linkerd ? "enabled" : "disabled"
      }
    )
    annotations = var.enable_linkerd ? {
      "linkerd.io/inject" = "enabled"
    } : {}
  }
}

# -----------------------------------------------------------------------------
# Service Account with Workload Identity
# -----------------------------------------------------------------------------
resource "kubernetes_service_account" "service" {
  metadata {
    name      = var.service_name
    namespace = var.create_namespace ? kubernetes_namespace.service[0].metadata[0].name : var.namespace
    annotations = var.gcp_service_account != "" ? {
      "iam.gke.io/gcp-service-account" = var.gcp_service_account
    } : {}
    labels = var.labels
  }
}

# -----------------------------------------------------------------------------
# ConfigMap
# -----------------------------------------------------------------------------
resource "kubernetes_config_map" "service" {
  count = length(var.config_data) > 0 ? 1 : 0

  metadata {
    name      = "${var.service_name}-config"
    namespace = var.create_namespace ? kubernetes_namespace.service[0].metadata[0].name : var.namespace
    labels    = var.labels
  }

  data = var.config_data
}

# -----------------------------------------------------------------------------
# Secret
# -----------------------------------------------------------------------------
resource "kubernetes_secret" "service" {
  count = length(var.secret_data) > 0 ? 1 : 0

  metadata {
    name      = "${var.service_name}-secret"
    namespace = var.create_namespace ? kubernetes_namespace.service[0].metadata[0].name : var.namespace
    labels    = var.labels
  }

  data = var.secret_data
  type = "Opaque"
}

# -----------------------------------------------------------------------------
# Deployment
# -----------------------------------------------------------------------------
resource "kubernetes_deployment" "service" {
  metadata {
    name      = var.service_name
    namespace = var.create_namespace ? kubernetes_namespace.service[0].metadata[0].name : var.namespace
    labels = merge(
      var.labels,
      {
        "app"     = var.service_name
        "version" = var.image_tag
      }
    )
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = var.service_name
      }
    }

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = var.max_surge
        max_unavailable = var.max_unavailable
      }
    }

    template {
      metadata {
        labels = merge(
          var.labels,
          {
            "app"     = var.service_name
            "version" = var.image_tag
          }
        )
        annotations = merge(
          var.pod_annotations,
          {
            "prometheus.io/scrape" = var.enable_prometheus ? "true" : "false"
            "prometheus.io/port"   = tostring(var.metrics_port)
            "prometheus.io/path"   = var.metrics_path
          }
        )
      }

      spec {
        service_account_name = kubernetes_service_account.service.metadata[0].name

        # Security context
        security_context {
          run_as_non_root = var.run_as_non_root
          run_as_user     = var.run_as_user
          fs_group        = var.fs_group
        }

        # Main container
        container {
          name              = var.service_name
          image             = "${var.image_repository}:${var.image_tag}"
          image_pull_policy = var.image_pull_policy

          # Ports
          dynamic "port" {
            for_each = var.ports
            content {
              name           = port.value.name
              container_port = port.value.container_port
              protocol       = lookup(port.value, "protocol", "TCP")
            }
          }

          # Environment variables from values
          dynamic "env" {
            for_each = var.environment_variables
            content {
              name  = env.key
              value = env.value
            }
          }

          # Environment from ConfigMap
          dynamic "env_from" {
            for_each = length(var.config_data) > 0 ? [1] : []
            content {
              config_map_ref {
                name = kubernetes_config_map.service[0].metadata[0].name
              }
            }
          }

          # Environment from Secret
          dynamic "env_from" {
            for_each = length(var.secret_data) > 0 ? [1] : []
            content {
              secret_ref {
                name = kubernetes_secret.service[0].metadata[0].name
              }
            }
          }

          # Resources
          resources {
            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }
            limits = {
              cpu    = var.cpu_limit
              memory = var.memory_limit
            }
          }

          # Health checks
          dynamic "liveness_probe" {
            for_each = var.liveness_probe_path != "" ? [1] : []
            content {
              http_get {
                path = var.liveness_probe_path
                port = var.health_check_port
              }
              initial_delay_seconds = var.liveness_initial_delay
              period_seconds        = var.liveness_period
              timeout_seconds       = var.liveness_timeout
              failure_threshold     = var.liveness_failure_threshold
            }
          }

          dynamic "readiness_probe" {
            for_each = var.readiness_probe_path != "" ? [1] : []
            content {
              http_get {
                path = var.readiness_probe_path
                port = var.health_check_port
              }
              initial_delay_seconds = var.readiness_initial_delay
              period_seconds        = var.readiness_period
              timeout_seconds       = var.readiness_timeout
              failure_threshold     = var.readiness_failure_threshold
            }
          }

          # Volume mounts
          dynamic "volume_mount" {
            for_each = var.volume_mounts
            content {
              name       = volume_mount.value.name
              mount_path = volume_mount.value.mount_path
              read_only  = lookup(volume_mount.value, "read_only", false)
            }
          }
        }

        # Volumes
        dynamic "volume" {
          for_each = var.volumes
          content {
            name = volume.value.name

            dynamic "persistent_volume_claim" {
              for_each = lookup(volume.value, "pvc_name", "") != "" ? [1] : []
              content {
                claim_name = volume.value.pvc_name
              }
            }

            dynamic "empty_dir" {
              for_each = lookup(volume.value, "empty_dir", false) ? [1] : []
              content {}
            }

            dynamic "config_map" {
              for_each = lookup(volume.value, "config_map_name", "") != "" ? [1] : []
              content {
                name = volume.value.config_map_name
              }
            }
          }
        }

        # Image pull secrets
        dynamic "image_pull_secrets" {
          for_each = var.image_pull_secrets
          content {
            name = image_pull_secrets.value
          }
        }

        # Node selector
        dynamic "node_selector" {
          for_each = length(var.node_selector) > 0 ? [var.node_selector] : []
          content {
            # Dynamic node selectors
          }
        }

        # Tolerations
        dynamic "toleration" {
          for_each = var.tolerations
          content {
            key      = toleration.value.key
            operator = toleration.value.operator
            value    = lookup(toleration.value, "value", null)
            effect   = toleration.value.effect
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      spec[0].template[0].metadata[0].annotations["kubectl.kubernetes.io/restartedAt"],
    ]
  }
}

# -----------------------------------------------------------------------------
# Service
# -----------------------------------------------------------------------------
resource "kubernetes_service" "service" {
  metadata {
    name      = var.service_name
    namespace = var.create_namespace ? kubernetes_namespace.service[0].metadata[0].name : var.namespace
    labels    = var.labels
    annotations = var.service_annotations
  }

  spec {
    type = var.service_type

    selector = {
      app = var.service_name
    }

    dynamic "port" {
      for_each = var.ports
      content {
        name        = port.value.name
        port        = port.value.service_port
        target_port = port.value.container_port
        protocol    = lookup(port.value, "protocol", "TCP")
      }
    }
  }
}

# -----------------------------------------------------------------------------
# Horizontal Pod Autoscaler
# -----------------------------------------------------------------------------
resource "kubernetes_horizontal_pod_autoscaler_v2" "service" {
  count = var.enable_hpa ? 1 : 0

  metadata {
    name      = var.service_name
    namespace = var.create_namespace ? kubernetes_namespace.service[0].metadata[0].name : var.namespace
    labels    = var.labels
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.service.metadata[0].name
    }

    min_replicas = var.hpa_min_replicas
    max_replicas = var.hpa_max_replicas

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = var.hpa_cpu_target
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = var.hpa_memory_target
        }
      }
    }
  }
}

# -----------------------------------------------------------------------------
# Pod Disruption Budget
# -----------------------------------------------------------------------------
resource "kubernetes_pod_disruption_budget_v1" "service" {
  count = var.enable_pdb ? 1 : 0

  metadata {
    name      = var.service_name
    namespace = var.create_namespace ? kubernetes_namespace.service[0].metadata[0].name : var.namespace
    labels    = var.labels
  }

  spec {
    min_available = var.pdb_min_available

    selector {
      match_labels = {
        app = var.service_name
      }
    }
  }
}
