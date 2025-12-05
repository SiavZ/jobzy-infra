# =============================================================================
# Cloud SQL MySQL Module for Jobzy Platform
# =============================================================================
# Creates MySQL instances for:
# - Booking Service (100 GB) - Custom
# - EasyAppointments (500 GB)
# - SuiteCRM (300 GB)
# - Payment Service (400 GB) - Custom, Critical
# - Pricing Service (20 GB) - Custom
# - Correlation DB (50 GB) - Custom
# =============================================================================

resource "random_id" "db_suffix" {
  byte_length = 4
}

# -----------------------------------------------------------------------------
# MySQL Instance
# -----------------------------------------------------------------------------
resource "google_sql_database_instance" "mysql" {
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
      binary_log_enabled             = var.environment == "prod"  # Required for replication
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
      name  = "character_set_server"
      value = "utf8mb4"
    }

    database_flags {
      name  = "collation_server"
      value = "utf8mb4_unicode_ci"
    }

    database_flags {
      name  = "slow_query_log"
      value = "on"
    }

    database_flags {
      name  = "long_query_time"
      value = "2"
    }

    database_flags {
      name  = "innodb_buffer_pool_size"
      value = var.innodb_buffer_pool_size
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

  name      = each.key
  instance  = google_sql_database_instance.mysql.name
  project   = var.project_id
  charset   = "utf8mb4"
  collation = "utf8mb4_unicode_ci"
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
  instance = google_sql_database_instance.mysql.name
  password = random_password.db_passwords[each.key].result
  project  = var.project_id
  host     = "%"  # Allow connections from any host within VPC
}

# -----------------------------------------------------------------------------
# Read Replica (for production)
# -----------------------------------------------------------------------------
resource "google_sql_database_instance" "read_replica" {
  count = var.environment == "prod" && var.create_read_replica ? var.replica_count : 0

  name                 = "${var.instance_name}-replica-${count.index}-${random_id.db_suffix.hex}"
  database_version     = var.database_version
  region               = var.region
  project              = var.project_id
  master_instance_name = google_sql_database_instance.mysql.name

  replica_configuration {
    failover_target = count.index == 0  # First replica is failover target
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

    database_flags {
      name  = "character_set_server"
      value = "utf8mb4"
    }

    user_labels = merge(var.labels, { "role" = "replica", "replica_index" = tostring(count.index) })
  }
}
