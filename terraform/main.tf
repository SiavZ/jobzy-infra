# GKE Cluster
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

  labels = local.common_labels
}

# Cloud SQL
module "cloud_sql" {
  source = "./modules/cloud-sql"

  project_id        = var.project_id
  region            = var.region
  environment       = var.environment
  instance_name     = "${local.resource_prefix}-postgres"

  database_version  = var.database_version
  tier              = var.database_tier
  disk_size         = 20
  availability_type = var.environment == "prod" ? "REGIONAL" : "ZONAL"

  labels = local.common_labels

  depends_on = [module.gke]
}

# Redis (Memorystore)
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

  depends_on = [module.gke]
}

# Kong Gateway
module "kong" {
  source = "./modules/kong"

  project_id   = var.project_id
  region       = var.region
  environment  = var.environment
  cluster_name = var.cluster_name

  namespace = local.kong_namespace
  replicas  = var.kong_replicas

  # Database config
  db_host     = module.cloud_sql.private_ip_address
  db_port     = 5432
  db_name     = "kong"
  db_user     = module.cloud_sql.kong_username
  db_password = module.cloud_sql.kong_password

  # Redis config
  redis_host = module.redis.host
  redis_port = 6379

  labels = local.common_labels

  depends_on = [module.gke, module.cloud_sql, module.redis]
}

# Keycloak
module "keycloak" {
  source = "./modules/keycloak"

  project_id   = var.project_id
  region       = var.region
  environment  = var.environment
  cluster_name = var.cluster_name

  namespace = local.keycloak_namespace
  replicas  = var.keycloak_replicas

  # Database config
  db_host     = module.cloud_sql.private_ip_address
  db_port     = 5432
  db_name     = "keycloak"
  db_user     = module.cloud_sql.keycloak_username
  db_password = module.cloud_sql.keycloak_password

  # Redis config (for sessions)
  redis_host = module.redis.host
  redis_port = 6379

  # Keycloak config
  admin_password = var.keycloak_admin_password
  hostname       = var.keycloak_hostname

  labels = local.common_labels

  depends_on = [module.gke, module.cloud_sql, module.redis]
}
