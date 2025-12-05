# =============================================================================
# Jobzy Platform - Main Terraform Configuration
# =============================================================================
# This file orchestrates all infrastructure modules for the Jobzy platform
# =============================================================================

# =============================================================================
# PHASE 1: NETWORKING & FOUNDATION
# =============================================================================

# -----------------------------------------------------------------------------
# VPC Network
# -----------------------------------------------------------------------------
module "vpc" {
  source = "./modules/vpc"

  project_id           = var.project_id
  region               = var.region
  environment          = var.environment
  network_name         = local.resource_prefix
  gke_subnet_cidr      = var.gke_subnet_cidr
  gke_pods_cidr        = var.gke_pods_cidr
  gke_services_cidr    = var.gke_services_cidr
  services_subnet_cidr = var.services_subnet_cidr

  labels = local.common_labels
}

# -----------------------------------------------------------------------------
# GKE Cluster
# -----------------------------------------------------------------------------
module "gke" {
  source = "./modules/gke"

  project_id   = var.project_id
  region       = var.region
  cluster_name = var.cluster_name
  environment  = var.environment

  num_nodes    = var.gke_num_nodes
  machine_type = var.gke_machine_type
  min_nodes    = var.gke_min_nodes
  max_nodes    = var.gke_max_nodes

  # Use custom VPC
  network    = module.vpc.network_name
  subnetwork = module.vpc.gke_subnet_name

  labels = local.common_labels

  depends_on = [module.vpc]
}

# =============================================================================
# PHASE 2: DATA LAYER
# =============================================================================

# -----------------------------------------------------------------------------
# Cloud SQL - PostgreSQL (Kong, Keycloak, Chatwoot, Astuto, Novu, Strapi)
# -----------------------------------------------------------------------------
module "cloud_sql_postgres" {
  source = "./modules/cloud-sql-postgres"

  project_id    = var.project_id
  region        = var.region
  environment   = var.environment
  instance_name = "${local.resource_prefix}-postgres"

  database_version = "POSTGRES_15"
  tier             = var.postgres_tier
  disk_size        = var.postgres_disk_size
  availability_type = var.environment == "prod" ? "REGIONAL" : "ZONAL"

  vpc_network_id         = module.vpc.network_id
  private_vpc_connection = module.vpc.private_vpc_connection

  databases = {
    kong     = {}
    keycloak = {}
    chatwoot = {}
    astuto   = {}
    novu     = {}
    strapi   = {}
  }

  create_read_replica = var.environment == "prod"
  max_connections     = var.postgres_max_connections

  labels = local.common_labels

  depends_on = [module.vpc, module.gke]
}

# -----------------------------------------------------------------------------
# Cloud SQL - MySQL (Booking, EasyAppointments, SuiteCRM, Payment, Pricing, Correlation)
# -----------------------------------------------------------------------------
module "cloud_sql_mysql" {
  source = "./modules/cloud-sql-mysql"

  project_id    = var.project_id
  region        = var.region
  environment   = var.environment
  instance_name = "${local.resource_prefix}-mysql"

  database_version = "MYSQL_8_0"
  tier             = var.mysql_tier
  disk_size        = var.mysql_disk_size
  availability_type = var.environment == "prod" ? "REGIONAL" : "ZONAL"

  vpc_network_id         = module.vpc.network_id
  private_vpc_connection = module.vpc.private_vpc_connection

  databases = {
    booking         = {}
    easyappointments = {}
    suitecrm        = {}
    payment         = {}
    pricing         = {}
    correlation     = {}
  }

  create_read_replica = var.environment == "prod"
  replica_count       = var.environment == "prod" ? 2 : 0
  max_connections     = var.mysql_max_connections

  labels = local.common_labels

  depends_on = [module.vpc, module.gke]
}

# -----------------------------------------------------------------------------
# Redis (Memorystore)
# -----------------------------------------------------------------------------
module "redis" {
  source = "./modules/redis"

  project_id    = var.project_id
  region        = var.region
  environment   = var.environment
  instance_name = "${local.resource_prefix}-redis"

  size_gb       = var.redis_size_gb
  redis_version = "7.0"
  tier          = var.environment == "prod" ? "STANDARD_HA" : "BASIC"

  labels = local.common_labels

  depends_on = [module.vpc, module.gke]
}

# -----------------------------------------------------------------------------
# Cloud Storage (GCS)
# -----------------------------------------------------------------------------
module "cloud_storage" {
  source = "./modules/cloud-storage"

  project_id  = var.project_id
  environment = var.environment
  location    = var.region

  cors_origins        = var.cors_origins
  gke_service_account = module.gke.node_service_account

  labels = local.common_labels

  depends_on = [module.gke]
}

# =============================================================================
# PHASE 3: PLATFORM SERVICES
# =============================================================================

# -----------------------------------------------------------------------------
# Kong Gateway
# -----------------------------------------------------------------------------
module "kong" {
  source = "./modules/kong"

  project_id   = var.project_id
  region       = var.region
  environment  = var.environment
  cluster_name = var.cluster_name

  namespace = local.kong_namespace
  replicas  = var.kong_replicas

  db_host     = module.cloud_sql_postgres.private_ip_address
  db_port     = 5432
  db_name     = "kong"
  db_user     = module.cloud_sql_postgres.database_users["kong"]
  db_password = module.cloud_sql_postgres.database_passwords["kong"]

  redis_host = module.redis.host
  redis_port = 6379

  labels = local.common_labels

  depends_on = [module.gke, module.cloud_sql_postgres, module.redis]
}

# -----------------------------------------------------------------------------
# Keycloak
# -----------------------------------------------------------------------------
module "keycloak" {
  source = "./modules/keycloak"

  project_id   = var.project_id
  region       = var.region
  environment  = var.environment
  cluster_name = var.cluster_name

  namespace = local.keycloak_namespace
  replicas  = var.keycloak_replicas

  db_host     = module.cloud_sql_postgres.private_ip_address
  db_port     = 5432
  db_name     = "keycloak"
  db_user     = module.cloud_sql_postgres.database_users["keycloak"]
  db_password = module.cloud_sql_postgres.database_passwords["keycloak"]

  redis_host = module.redis.host
  redis_port = 6379

  admin_password = var.keycloak_admin_password
  hostname       = var.keycloak_hostname

  labels = local.common_labels

  depends_on = [module.gke, module.cloud_sql_postgres, module.redis]
}

# -----------------------------------------------------------------------------
# Cloud Run (Frontend)
# -----------------------------------------------------------------------------
module "cloud_run" {
  source = "./modules/cloud-run"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment

  service_name    = "${local.resource_prefix}-frontend"
  container_image = var.frontend_image
  container_port  = 3000

  min_instances = var.environment == "prod" ? 1 : 0
  max_instances = var.frontend_max_instances

  vpc_network           = module.vpc.network_name
  service_account_email = module.gke.node_service_account

  custom_domain = var.frontend_domain

  environment_variables = {
    NODE_ENV              = var.environment == "prod" ? "production" : "development"
    NEXT_PUBLIC_API_URL   = "https://api.${var.domain}"
    NEXT_PUBLIC_AUTH_URL  = "https://auth.${var.domain}"
  }

  labels = local.common_labels

  depends_on = [module.vpc, module.gke]
}

# =============================================================================
# PHASE 4: OBSERVABILITY
# =============================================================================

# -----------------------------------------------------------------------------
# Prometheus + Grafana
# -----------------------------------------------------------------------------
module "observability" {
  count = var.enable_observability ? 1 : 0

  source = "./modules/observability"

  namespace                 = local.monitoring_namespace
  prometheus_retention      = var.prometheus_retention
  prometheus_storage_size   = var.prometheus_storage_size
  monitored_namespaces      = local.all_namespaces
  grafana_admin_password    = var.grafana_admin_password
  grafana_hosts             = ["grafana.${var.domain}"]
  slack_webhook_url         = var.slack_webhook_url
  slack_channel             = var.slack_channel
  pagerduty_service_key     = var.pagerduty_service_key
  create_service_monitors   = true

  labels = local.common_labels

  depends_on = [module.gke]
}

# -----------------------------------------------------------------------------
# ELK Stack
# -----------------------------------------------------------------------------
module "elk_stack" {
  count = var.enable_elk ? 1 : 0

  source = "./modules/elk-stack"

  namespace                  = local.logging_namespace
  elasticsearch_replicas     = var.environment == "prod" ? 3 : 1
  elasticsearch_storage_size = var.elasticsearch_storage_size
  enable_jaeger              = var.enable_jaeger
  log_retention_days         = var.log_retention_days

  labels = local.common_labels

  depends_on = [module.gke]
}

# =============================================================================
# PHASE 5: SERVICE MESH
# =============================================================================

# -----------------------------------------------------------------------------
# Linkerd
# -----------------------------------------------------------------------------
module "linkerd" {
  count = var.enable_linkerd ? 1 : 0

  source = "./modules/linkerd"

  linkerd_version = var.linkerd_version
  ha_enabled      = var.environment == "prod"
  enable_viz      = true
  enable_jaeger   = var.enable_jaeger

  auto_inject_namespaces = local.mesh_namespaces

  labels = local.common_labels

  depends_on = [module.gke]
}

# =============================================================================
# PHASE 6: DNS
# =============================================================================

# -----------------------------------------------------------------------------
# Cloud DNS
# -----------------------------------------------------------------------------
module "cloud_dns" {
  count = var.manage_dns ? 1 : 0

  source = "./modules/cloud-dns"

  project_id   = var.project_id
  zone_name    = replace(var.domain, ".", "-")
  domain       = var.domain
  enable_dnssec = var.environment == "prod"

  frontend_ip   = module.cloud_run.service_url
  kong_ip       = module.kong.loadbalancer_ip
  keycloak_ip   = module.keycloak.loadbalancer_ip

  enable_service_subdomains    = var.enable_service_subdomains
  enable_monitoring_subdomains = var.enable_monitoring_subdomains

  create_private_zone = true
  vpc_network_id      = module.vpc.network_id

  labels = local.common_labels

  depends_on = [module.kong, module.keycloak, module.cloud_run]
}

# =============================================================================
# MICROSERVICES (Examples - uncomment and configure as needed)
# =============================================================================

# # Custom Booking Service
# module "booking_service" {
#   source = "./modules/microservice"

#   service_name     = "booking-service"
#   namespace        = "jobzy"
#   create_namespace = true
#   image_repository = "gcr.io/${var.project_id}/booking-service"
#   image_tag        = "latest"

#   replicas       = var.environment == "prod" ? 2 : 1
#   cpu_request    = "200m"
#   cpu_limit      = "1000m"
#   memory_request = "512Mi"
#   memory_limit   = "1Gi"

#   ports = [{
#     name           = "http"
#     container_port = 8080
#     service_port   = 80
#   }]

#   environment_variables = {
#     DATABASE_HOST = module.cloud_sql_mysql.private_ip_address
#     DATABASE_NAME = "booking"
#     REDIS_HOST    = module.redis.host
#   }

#   secret_data = {
#     DATABASE_PASSWORD = module.cloud_sql_mysql.database_passwords["booking"]
#   }

#   enable_hpa        = var.environment == "prod"
#   hpa_min_replicas  = 2
#   hpa_max_replicas  = 10

#   enable_linkerd = var.enable_linkerd

#   labels = local.common_labels

#   depends_on = [module.gke, module.cloud_sql_mysql, module.redis]
# }

# # Custom Payment Service
# module "payment_service" {
#   source = "./modules/microservice"

#   service_name     = "payment-service"
#   namespace        = "jobzy"
#   image_repository = "gcr.io/${var.project_id}/payment-service"
#   image_tag        = "latest"

#   replicas       = var.environment == "prod" ? 3 : 1
#   cpu_request    = "500m"
#   cpu_limit      = "2000m"
#   memory_request = "1Gi"
#   memory_limit   = "2Gi"

#   ports = [{
#     name           = "http"
#     container_port = 8080
#     service_port   = 80
#   }]

#   environment_variables = {
#     DATABASE_HOST = module.cloud_sql_mysql.private_ip_address
#     DATABASE_NAME = "payment"
#     REDIS_HOST    = module.redis.host
#     STRIPE_MODE   = var.environment == "prod" ? "live" : "test"
#   }

#   secret_data = {
#     DATABASE_PASSWORD = module.cloud_sql_mysql.database_passwords["payment"]
#     STRIPE_SECRET_KEY = var.stripe_secret_key
#   }

#   enable_hpa        = true
#   hpa_min_replicas  = 3
#   hpa_max_replicas  = 20

#   enable_pdb       = true
#   pdb_min_available = "2"

#   enable_linkerd = var.enable_linkerd

#   labels = local.common_labels

#   depends_on = [module.gke, module.cloud_sql_mysql, module.redis]
# }
