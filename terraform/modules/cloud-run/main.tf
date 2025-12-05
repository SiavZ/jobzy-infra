# =============================================================================
# Cloud Run Module for Jobzy Frontend (Next.js PWA)
# =============================================================================
# Deploys the Next.js frontend as a serverless container on Cloud Run
# Features:
# - Auto-scaling (0-10+ instances)
# - HTTPS with managed SSL
# - Custom domain support
# - VPC connector for private resources
# =============================================================================

# -----------------------------------------------------------------------------
# VPC Connector for accessing private resources
# -----------------------------------------------------------------------------
resource "google_vpc_access_connector" "connector" {
  name          = "${var.service_name}-connector"
  region        = var.region
  project       = var.project_id
  network       = var.vpc_network
  ip_cidr_range = var.connector_cidr

  min_instances = 2
  max_instances = 10

  machine_type = "e2-micro"
}

# -----------------------------------------------------------------------------
# Cloud Run Service - Frontend
# -----------------------------------------------------------------------------
resource "google_cloud_run_v2_service" "frontend" {
  name     = var.service_name
  location = var.region
  project  = var.project_id

  template {
    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    vpc_access {
      connector = google_vpc_access_connector.connector.id
      egress    = "PRIVATE_RANGES_ONLY"
    }

    timeout = "60s"

    containers {
      name  = "frontend"
      image = var.container_image

      ports {
        container_port = var.container_port
      }

      resources {
        limits = {
          cpu    = var.cpu_limit
          memory = var.memory_limit
        }
        cpu_idle          = true
        startup_cpu_boost = true
      }

      # Environment variables
      dynamic "env" {
        for_each = var.environment_variables
        content {
          name  = env.key
          value = env.value
        }
      }

      # Secret environment variables
      dynamic "env" {
        for_each = var.secret_environment_variables
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = env.value.secret_name
              version = env.value.version
            }
          }
        }
      }

      startup_probe {
        http_get {
          path = "/api/health"
          port = var.container_port
        }
        initial_delay_seconds = 10
        timeout_seconds       = 5
        period_seconds        = 10
        failure_threshold     = 3
      }

      liveness_probe {
        http_get {
          path = "/api/health"
          port = var.container_port
        }
        initial_delay_seconds = 30
        timeout_seconds       = 5
        period_seconds        = 30
        failure_threshold     = 3
      }
    }

    service_account = var.service_account_email

    labels = var.labels
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,  # Allow CI/CD to update image
    ]
  }
}

# -----------------------------------------------------------------------------
# IAM - Allow unauthenticated access (public website)
# -----------------------------------------------------------------------------
resource "google_cloud_run_v2_service_iam_member" "public_access" {
  count    = var.allow_unauthenticated ? 1 : 0
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.frontend.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# -----------------------------------------------------------------------------
# Custom Domain Mapping
# -----------------------------------------------------------------------------
resource "google_cloud_run_domain_mapping" "primary" {
  count    = var.custom_domain != "" ? 1 : 0
  location = var.region
  name     = var.custom_domain
  project  = var.project_id

  metadata {
    namespace = var.project_id
    labels    = var.labels
  }

  spec {
    route_name = google_cloud_run_v2_service.frontend.name
  }
}

resource "google_cloud_run_domain_mapping" "www" {
  count    = var.custom_domain != "" ? 1 : 0
  location = var.region
  name     = "www.${var.custom_domain}"
  project  = var.project_id

  metadata {
    namespace = var.project_id
    labels    = var.labels
  }

  spec {
    route_name = google_cloud_run_v2_service.frontend.name
  }
}
