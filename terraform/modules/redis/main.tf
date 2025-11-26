resource "google_redis_instance" "redis" {
  name           = var.instance_name
  tier           = var.tier
  memory_size_gb = var.size_gb
  region         = var.region

  redis_version     = "REDIS_${replace(var.redis_version, ".", "_")}"
  display_name      = "${var.instance_name}-redis"
  reserved_ip_range = var.reserved_ip_range

  # Network configuration
  authorized_network = data.google_compute_network.default.id
  connect_mode       = "PRIVATE_SERVICE_ACCESS"

  # Redis configuration
  redis_configs = {
    maxmemory-policy = "allkeys-lru"
  }

  # Maintenance window
  maintenance_policy {
    weekly_maintenance_window {
      day = "SUNDAY"
      start_time {
        hours   = 3
        minutes = 0
        seconds = 0
        nanos   = 0
      }
    }
  }

  labels = var.labels

  lifecycle {
    prevent_destroy = false
  }
}

data "google_compute_network" "default" {
  name = "default"
}
