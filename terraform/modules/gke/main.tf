resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = "default"
  subnetwork = "default"

  # Enabling Autopilot would simplify management but we use standard for more control
  # For Autopilot, comment out node_pool and set enable_autopilot = true

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Maintenance window
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  # Addons
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  # Master authorized networks (optional - add your IPs)
  # master_authorized_networks_config {
  #   cidr_blocks {
  #     cidr_block   = "0.0.0.0/0"
  #     display_name = "All"
  #   }
  # }

  resource_labels = var.labels
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.num_nodes

  autoscaling {
    min_node_count = var.min_nodes
    max_node_count = var.max_nodes
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    preemptible  = var.environment != "prod"
    machine_type = var.machine_type

    # Google recommends custom service accounts with minimum permissions
    # For simplicity, using default compute service account
    # In production, create a dedicated service account
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = merge(
      var.labels,
      {
        "node-pool" = "${var.cluster_name}-node-pool"
      }
    )

    metadata = {
      disable-legacy-endpoints = "true"
    }

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    tags = ["gke-node", "${var.cluster_name}-node"]
  }

  lifecycle {
    ignore_changes = [
      node_count
    ]
  }
}
