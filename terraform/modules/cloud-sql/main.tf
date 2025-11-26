resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "random_password" "kong_password" {
  length  = 32
  special = true
}

resource "random_password" "keycloak_password" {
  length  = 32
  special = true
}

resource "google_sql_database_instance" "postgres" {
  name             = "${var.instance_name}-${random_id.db_name_suffix.hex}"
  database_version = var.database_version
  region           = var.region

  settings {
    tier              = var.tier
    disk_size         = var.disk_size
    disk_type         = "PD_SSD"
    availability_type = var.availability_type

    backup_configuration {
      enabled            = true
      start_time         = "02:00"
      point_in_time_recovery_enabled = var.environment == "prod" ? true : false
      backup_retention_settings {
        retained_backups = 7
      }
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = data.google_compute_network.default.id
      require_ssl     = true
    }

    database_flags {
      name  = "max_connections"
      value = "200"
    }

    database_flags {
      name  = "cloudsql.iam_authentication"
      value = "on"
    }

    maintenance_window {
      day          = 7
      hour         = 3
      update_track = "stable"
    }

    insights_config {
      query_insights_enabled  = true
      query_string_length     = 1024
      record_application_tags = true
    }

    user_labels = var.labels
  }

  deletion_protection = var.environment == "prod" ? true : false

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

# Kong database
resource "google_sql_database" "kong" {
  name     = "kong"
  instance = google_sql_database_instance.postgres.name
}

# Keycloak database
resource "google_sql_database" "keycloak" {
  name     = "keycloak"
  instance = google_sql_database_instance.postgres.name
}

# Kong user
resource "google_sql_user" "kong" {
  name     = "kong"
  instance = google_sql_database_instance.postgres.name
  password = random_password.kong_password.result
}

# Keycloak user
resource "google_sql_user" "keycloak" {
  name     = "keycloak"
  instance = google_sql_database_instance.postgres.name
  password = random_password.keycloak_password.result
}

# Enable private IP
data "google_compute_network" "default" {
  name = "default"
}

resource "google_compute_global_address" "private_ip_address" {
  name          = "${var.instance_name}-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = data.google_compute_network.default.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = data.google_compute_network.default.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}
