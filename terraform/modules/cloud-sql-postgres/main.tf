# =============================================================================
# Cloud SQL PostgreSQL Module for Jobzy Platform
# =============================================================================
# Creates PostgreSQL instances for:
# - Keycloak (5 GB)
# - Kong (2 GB)
# - Chatwoot (200 GB)
# - Astuto (150 GB)
# - Novu (100 GB)
# - Strapi (50 GB)
# =============================================================================

resource "random_id" "db_suffix" {
  byte_length = 4
}

# -----------------------------------------------------------------------------
# PostgreSQL Instance
# -----------------------------------------------------------------------------
resource "google_sql_database_instance" "postgres" {
  name                = "${var.instance_name}-${random_id.db_suffix.hex}"
  database_version    = var.database_version
  region              = var.region
  project             = var.project_id
  deletion_protection = var.environment == "prod"

  settings {
    tier              = var.tier
    disk_size         = var.disk_size
    disk_type         = "PD_SSD"
    disk_autoresize   = true
    availability_type = var.availability_type

    backup_configuration {
      enabled                        = true
      start_time                     = "02:00"
      point_in_time_recovery_enabled = var.environment == "prod"
      transaction_log_retention_days = var.environment == "prod" ? 7 : 3
      backup_retention_settings {
        retained_backups = var.environment == "prod" ? 14 : 7
      }
    }

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = var.vpc_network_id
      require_ssl                                   = true
      enable_private_path_for_google_cloud_services = true
    }

    database_flags {
      name  = "max_connections"
      value = var.max_connections
    }

    database_flags {
      name  = "cloudsql.iam_authentication"
      value = "on"
    }

    database_flags {
      name  = "log_checkpoints"
      value = "on"
    }

    database_flags {
      name  = "log_connections"
      value = "on"
    }

    database_flags {
      name  = "log_disconnections"
      value = "on"
    }

    maintenance_window {
      day          = 7  # Sunday
      hour         = 3
      update_track = "stable"
    }

    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = true
    }

    user_labels = var.labels
  }

  depends_on = [var.private_vpc_connection]
}

# -----------------------------------------------------------------------------
# Databases
# -----------------------------------------------------------------------------
resource "google_sql_database" "databases" {
  for_each = var.databases

  name     = each.key
  instance = google_sql_database_instance.postgres.name
  project  = var.project_id
}

# -----------------------------------------------------------------------------
# Database Users
# -----------------------------------------------------------------------------
resource "random_password" "db_passwords" {
  for_each = var.databases

  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "google_sql_user" "users" {
  for_each = var.databases

  name     = each.key
  instance = google_sql_database_instance.postgres.name
  password = random_password.db_passwords[each.key].result
  project  = var.project_id
}

# -----------------------------------------------------------------------------
# Read Replica (for production)
# -----------------------------------------------------------------------------
resource "google_sql_database_instance" "read_replica" {
  count = var.environment == "prod" && var.create_read_replica ? 1 : 0

  name                 = "${var.instance_name}-replica-${random_id.db_suffix.hex}"
  database_version     = var.database_version
  region               = var.region
  project              = var.project_id
  master_instance_name = google_sql_database_instance.postgres.name

  replica_configuration {
    failover_target = false
  }

  settings {
    tier            = var.replica_tier != "" ? var.replica_tier : var.tier
    disk_size       = var.disk_size
    disk_type       = "PD_SSD"
    disk_autoresize = true

    ip_configuration {
      ipv4_enabled    = false
      private_network = var.vpc_network_id
      require_ssl     = true
    }

    database_flags {
      name  = "max_connections"
      value = var.max_connections
    }

    user_labels = merge(var.labels, { "role" = "replica" })
  }
}
