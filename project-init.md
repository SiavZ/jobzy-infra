# Jobzy Infrastructure Repository Initialization Guide

**Date:** November 26, 2025  
**Repository:** jobzy-infra  
**Purpose:** Complete Terraform IaC for Jobzy microservices on GCP

---

## 📋 Project Overview

This is the **complete Infrastructure-as-Code (IaC)** repository for Jobzy's cloud infrastructure on Google Cloud Platform. It includes:

- ✅ GKE Kubernetes cluster (Kong Gateway + Keycloak)
- ✅ Cloud SQL (PostgreSQL database)
- ✅ Memorystore (Redis cache)
- ✅ Terraform state management (GCS backend)
- ✅ CI/CD automation (Cloud Build)
- ✅ Multi-environment configuration (dev, staging, prod)

---

## 🏗️ Complete Directory Structure

```
jobzy-infra/
├── README.md                           # Main documentation
├── .gitignore                          # Git ignore rules
├── .github/
│   └── CONTRIBUTING.md                 # Contribution guidelines
│
├── terraform/
│   ├── backend.tf                      # GCS backend configuration
│   ├── provider.tf                     # GCP + Kubernetes providers
│   ├── variables.tf                    # Input variables
│   ├── locals.tf                       # Local values
│   ├── main.tf                         # Main resource orchestration
│   ├── outputs.tf                      # Output values
│   ├── .gitignore                      # Terraform-specific ignores
│   │
│   ├── modules/
│   │   ├── gke/
│   │   │   ├── main.tf                 # GKE cluster definition
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── README.md
│   │   │
│   │   ├── cloud-sql/
│   │   │   ├── main.tf                 # Cloud SQL instance
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── README.md
│   │   │
│   │   ├── redis/
│   │   │   ├── main.tf                 # Memorystore Redis
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── README.md
│   │   │
│   │   ├── kong/
│   │   │   ├── main.tf                 # Kong Kubernetes deployment
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   ├── manifests.tf            # Kong K8s manifests
│   │   │   └── README.md
│   │   │
│   │   └── keycloak/
│   │       ├── main.tf                 # Keycloak Kubernetes deployment
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       ├── manifests.tf            # Keycloak K8s manifests
│   │       └── README.md
│   │
│   ├── environments/
│   │   ├── dev.tfvars                  # Development environment
│   │   ├── staging.tfvars              # Staging environment
│   │   └── prod.tfvars                 # Production environment
│   │
│   └── scripts/
│       ├── init.sh                     # Initialize GCS bucket
│       ├── plan.sh                     # Terraform plan wrapper
│       ├── apply.sh                    # Terraform apply wrapper
│       ├── destroy.sh                  # Terraform destroy wrapper
│       └── get-outputs.sh              # Retrieve infrastructure IPs
│
├── kubernetes/
│   ├── overlays/
│   │   ├── dev/
│   │   │   ├── kustomization.yaml
│   │   │   └── patches/
│   │   ├── staging/
│   │   │   ├── kustomization.yaml
│   │   │   └── patches/
│   │   └── prod/
│   │       ├── kustomization.yaml
│   │       └── patches/
│   │
│   └── base/
│       ├── kong/
│       │   ├── namespace.yaml
│       │   ├── deployment.yaml
│       │   ├── service.yaml
│       │   ├── configmap.yaml
│       │   ├── secret.yaml
│       │   └── kustomization.yaml
│       │
│       └── keycloak/
│           ├── namespace.yaml
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── configmap.yaml
│           ├── secret.yaml
│           └── kustomization.yaml
│
├── cloudbuild/
│   ├── cloudbuild.yaml                 # Main CI/CD pipeline
│   ├── cloudbuild-plan.yaml            # Plan-only pipeline
│   ├── cloudbuild-destroy.yaml         # Destroy pipeline (manual trigger)
│   └── README.md
│
├── docs/
│   ├── ARCHITECTURE.md                 # Architecture overview
│   ├── SETUP.md                        # Initial setup guide
│   ├── DEPLOYMENT.md                   # Deployment procedures
│   ├── TROUBLESHOOTING.md              # Common issues + solutions
│   ├── COST-OPTIMIZATION.md            # Cost management
│   └── SECURITY.md                     # Security considerations
│
├── scripts/
│   ├── create-gcs-bucket.sh            # Create state bucket
│   ├── create-service-account.sh       # Create Terraform SA
│   ├── verify-setup.sh                 # Verify everything works
│   ├── backup-state.sh                 # Manual state backup
│   ├── restore-state.sh                # Manual state restore
│   └── cleanup.sh                      # Clean up resources
│
└── .editorconfig                       # Editor configuration

```

---

## 📝 Core Files to Create

### **1. README.md** (Root)

```markdown
# Jobzy Infrastructure (jobzy-infra)

Complete Infrastructure-as-Code for Jobzy's microservices on Google Cloud Platform.

## Quick Start

1. **Prerequisites**
   - gcloud CLI installed
   - kubectl installed
   - Terraform 1.0+

2. **Initialize**
   ```bash
   ./scripts/create-gcs-bucket.sh
   ./scripts/create-service-account.sh
   cd terraform && terraform init
   ```

3. **Deploy**
   ```bash
   ./scripts/plan.sh prod
   ./scripts/apply.sh prod
   ```

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Setup Guide](docs/SETUP.md)
- [Deployment](docs/DEPLOYMENT.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

## Structure

- `terraform/` - Terraform configuration
- `kubernetes/` - Kubernetes manifests
- `cloudbuild/` - CI/CD configuration
- `docs/` - Documentation
- `scripts/` - Utility scripts
```

### **2. .gitignore**

```bash
# Terraform
*.tfstate
*.tfstate.*
*.tfvars.local
.terraform/
.terraform.lock.hcl
tfplan
crash.log
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Credentials & Keys
terraform-key.json
*.key
*.pem
*.p12
credentials.json
service-account-key.json

# IDE
.vscode/
.idea/
*.swp
*.swo
*~
.DS_Store

# OS
.DS_Store
Thumbs.db

# Environment
.env
.env.local
*.local
```

### **3. terraform/backend.tf**

```hcl
terraform {
  backend "gcs" {
    bucket  = "jobzy-terraform-state-prod"
    prefix  = "jobzy/prod"
    encryption_key = ""  # Set via environment variable
  }
}
```

### **4. terraform/provider.tf**

```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

provider "kubernetes" {
  host                   = "https://${module.gke.cluster_endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.cluster_ca_certificate)
}

provider "kubectl" {
  host                   = "https://${module.gke.cluster_endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.cluster_ca_certificate)
  load_config_file       = false
}

data "google_client_config" "default" {}
```

### **5. terraform/variables.tf**

```hcl
variable "project_id" {
  description = "GCP Project ID"
  type        = string
  validation {
    condition     = length(var.project_id) > 0
    error_message = "Project ID cannot be empty"
  }
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "europe-north1"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod"
  }
}

variable "cluster_name" {
  description = "GKE Cluster name"
  type        = string
}

variable "gke_num_nodes" {
  description = "Initial number of GKE nodes"
  type        = number
  default     = 3
  validation {
    condition     = var.gke_num_nodes >= 1 && var.gke_num_nodes <= 100
    error_message = "Node count must be between 1 and 100"
  }
}

variable "gke_machine_type" {
  description = "GKE node machine type"
  type        = string
  default     = "n1-standard-2"
}

variable "gke_min_nodes" {
  description = "Minimum number of nodes for autoscaling"
  type        = number
  default     = 2
}

variable "gke_max_nodes" {
  description = "Maximum number of nodes for autoscaling"
  type        = number
  default     = 10
}

variable "database_tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-f1-micro"
}

variable "database_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "POSTGRES_15"
}

variable "redis_size_gb" {
  description = "Redis instance size in GB"
  type        = number
  default     = 1
}

variable "kong_replicas" {
  description = "Number of Kong replicas"
  type        = number
  default     = 3
}

variable "keycloak_replicas" {
  description = "Number of Keycloak replicas"
  type        = number
  default     = 2
}

variable "keycloak_admin_password" {
  description = "Keycloak admin password"
  type        = string
  sensitive   = true
}

variable "keycloak_hostname" {
  description = "Keycloak hostname"
  type        = string
  default     = "auth.jobzy.fi"
}

variable "labels" {
  description = "Common labels for all resources"
  type        = map(string)
  default = {
    "project"     = "jobzy"
    "managed_by"  = "terraform"
    "created_at"  = "2025-11-26"
  }
}
```

### **6. terraform/locals.tf**

```hcl
locals {
  resource_prefix = "jobzy-${var.environment}"
  
  common_labels = merge(
    var.labels,
    {
      "environment" = var.environment
      "cluster"     = var.cluster_name
    }
  )
  
  kong_namespace   = "kong-system"
  keycloak_namespace = "keycloak"
  
  database_name = "jobzy_${replace(var.environment, "-", "_")}"
}
```

### **7. terraform/main.tf**

```hcl
# GKE Cluster
module "gke" {
  source = "./modules/gke"

  project_id       = var.project_id
  region           = var.region
  cluster_name     = var.cluster_name
  environment      = var.environment
  
  num_nodes        = var.gke_num_nodes
  machine_type     = var.gke_machine_type
  min_nodes        = var.gke_min_nodes
  max_nodes        = var.gke_max_nodes
  
  labels           = local.common_labels
}

# Cloud SQL
module "cloud_sql" {
  source = "./modules/cloud-sql"

  project_id           = var.project_id
  region               = var.region
  environment          = var.environment
  instance_name        = "${local.resource_prefix}-postgres"
  
  database_version     = var.database_version
  tier                 = var.database_tier
  disk_size            = 20
  availability_type    = var.environment == "prod" ? "REGIONAL" : "ZONAL"
  
  labels               = local.common_labels
  
  depends_on = [module.gke]
}

# Redis (Memorystore)
module "redis" {
  source = "./modules/redis"

  project_id     = var.project_id
  region         = var.region
  environment    = var.environment
  instance_name  = "${local.resource_prefix}-redis"
  
  size_gb        = var.redis_size_gb
  redis_version  = "7.0"
  tier           = var.environment == "prod" ? "STANDARD_HA" : "BASIC"
  
  labels         = local.common_labels
  
  depends_on = [module.gke]
}

# Kong Gateway
module "kong" {
  source = "./modules/kong"

  project_id      = var.project_id
  region          = var.region
  environment     = var.environment
  cluster_name    = var.cluster_name
  
  namespace       = local.kong_namespace
  replicas        = var.kong_replicas
  
  # Database config
  db_host         = module.cloud_sql.private_ip_address
  db_port         = 5432
  db_name         = "kong"
  db_user         = module.cloud_sql.kong_username
  db_password     = module.cloud_sql.kong_password
  
  # Redis config
  redis_host      = module.redis.host
  redis_port      = 6379
  
  labels          = local.common_labels
  
  depends_on = [module.gke, module.cloud_sql, module.redis]
}

# Keycloak
module "keycloak" {
  source = "./modules/keycloak"

  project_id      = var.project_id
  region          = var.region
  environment     = var.environment
  cluster_name    = var.cluster_name
  
  namespace       = local.keycloak_namespace
  replicas        = var.keycloak_replicas
  
  # Database config
  db_host         = module.cloud_sql.private_ip_address
  db_port         = 5432
  db_name         = "keycloak"
  db_user         = module.cloud_sql.keycloak_username
  db_password     = module.cloud_sql.keycloak_password
  
  # Redis config (for sessions)
  redis_host      = module.redis.host
  redis_port      = 6379
  
  # Keycloak config
  admin_password  = var.keycloak_admin_password
  hostname        = var.keycloak_hostname
  
  labels          = local.common_labels
  
  depends_on = [module.gke, module.cloud_sql, module.redis]
}
```

### **8. terraform/outputs.tf**

```hcl
output "gke_cluster_name" {
  description = "GKE Cluster name"
  value       = module.gke.cluster_name
}

output "gke_cluster_endpoint" {
  description = "GKE Cluster endpoint"
  value       = module.gke.cluster_endpoint
  sensitive   = true
}

output "gke_region" {
  description = "GKE Cluster region"
  value       = var.region
}

output "cloud_sql_instance_name" {
  description = "Cloud SQL instance name"
  value       = module.cloud_sql.instance_name
}

output "cloud_sql_private_ip" {
  description = "Cloud SQL private IP address"
  value       = module.cloud_sql.private_ip_address
}

output "cloud_sql_connection_name" {
  description = "Cloud SQL connection name (for Cloud SQL Proxy)"
  value       = module.cloud_sql.connection_name
}

output "redis_host" {
  description = "Redis host IP"
  value       = module.redis.host
}

output "redis_port" {
  description = "Redis port"
  value       = module.redis.port
}

output "kong_loadbalancer_ip" {
  description = "Kong Gateway LoadBalancer IP"
  value       = module.kong.loadbalancer_ip
}

output "kong_admin_url" {
  description = "Kong Admin API URL"
  value       = module.kong.admin_url
}

output "keycloak_loadbalancer_ip" {
  description = "Keycloak LoadBalancer IP"
  value       = module.keycloak.loadbalancer_ip
}

output "keycloak_url" {
  description = "Keycloak URL"
  value       = module.keycloak.keycloak_url
}

output "kubectl_context" {
  description = "kubectl context command"
  value       = "gcloud container clusters get-credentials ${module.gke.cluster_name} --region ${var.region}"
}
```

### **9. terraform/environments/prod.tfvars**

```hcl
project_id               = "jobzy-production"
region                   = "europe-north1"
environment              = "prod"
cluster_name             = "jobzy-production"

gke_num_nodes            = 3
gke_machine_type         = "n1-standard-2"
gke_min_nodes            = 2
gke_max_nodes            = 10

database_tier            = "db-custom-2-8192"
database_version         = "POSTGRES_15"

redis_size_gb            = 5

kong_replicas            = 3
keycloak_replicas        = 2

keycloak_hostname        = "auth.jobzy.fi"
```

### **10. terraform/environments/dev.tfvars**

```hcl
project_id               = "jobzy-dev"
region                   = "europe-north1"
environment              = "dev"
cluster_name             = "jobzy-dev"

gke_num_nodes            = 1
gke_machine_type         = "n1-standard-2"
gke_min_nodes            = 1
gke_max_nodes            = 3

database_tier            = "db-f1-micro"
database_version         = "POSTGRES_15"

redis_size_gb            = 1

kong_replicas            = 1
keycloak_replicas        = 1

keycloak_hostname        = "auth-dev.jobzy.fi"
```

### **11. terraform/environments/staging.tfvars**

```hcl
project_id               = "jobzy-staging"
region                   = "europe-north1"
environment              = "staging"
cluster_name             = "jobzy-staging"

gke_num_nodes            = 2
gke_machine_type         = "n1-standard-2"
gke_min_nodes            = 1
gke_max_nodes            = 5

database_tier            = "db-custom-1-4096"
database_version         = "POSTGRES_15"

redis_size_gb            = 2

kong_replicas            = 2
keycloak_replicas        = 1

keycloak_hostname        = "auth-staging.jobzy.fi"
```

### **12. cloudbuild.yaml**

```yaml
steps:
  # Step 1: Terraform Init
  - name: 'hashicorp/terraform:latest'
    id: 'terraform-init'
    entrypoint: 'bash'
    args:
      - '-c'
      - |
        cd terraform
        terraform init

  # Step 2: Terraform Validate
  - name: 'hashicorp/terraform:latest'
    id: 'terraform-validate'
    entrypoint: 'bash'
    args:
      - '-c'
      - |
        cd terraform
        terraform validate

  # Step 3: Terraform Format Check
  - name: 'hashicorp/terraform:latest'
    id: 'terraform-fmt'
    entrypoint: 'bash'
    args:
      - '-c'
      - |
        cd terraform
        terraform fmt -check

  # Step 4: Terraform Plan
  - name: 'hashicorp/terraform:latest'
    id: 'terraform-plan'
    entrypoint: 'bash'
    env:
      - 'TF_VAR_keycloak_admin_password=${_KEYCLOAK_ADMIN_PASSWORD}'
    args:
      - '-c'
      - |
        cd terraform
        terraform plan \
          -var-file="environments/${_ENVIRONMENT}.tfvars" \
          -out=tfplan

  # Step 5: Terraform Apply (only on main branch)
  - name: 'hashicorp/terraform:latest'
    id: 'terraform-apply'
    entrypoint: 'bash'
    env:
      - 'TF_VAR_keycloak_admin_password=${_KEYCLOAK_ADMIN_PASSWORD}'
    args:
      - '-c'
      - |
        if [ "$BRANCH_NAME" = "main" ]; then
          cd terraform
          terraform apply -auto-approve tfplan
        else
          echo "Skipping apply on non-main branch"
        fi

timeout: '3600s'

substitutions:
  _ENVIRONMENT: 'prod'
  _KEYCLOAK_ADMIN_PASSWORD: ''  # Set via Cloud Build trigger

onPush:
  branch: '^main$'
```

---

## 🚀 Module Files Needed

Each module needs:
- `main.tf` - Resource definitions
- `variables.tf` - Input variables
- `outputs.tf` - Output values
- `README.md` - Module documentation

**Modules to create:**
1. `modules/gke/` - GKE cluster
2. `modules/cloud-sql/` - PostgreSQL database
3. `modules/redis/` - Memorystore Redis
4. `modules/kong/` - Kong Kubernetes deployment
5. `modules/keycloak/` - Keycloak Kubernetes deployment

---

## 📚 Documentation Files Needed

Create in `docs/`:
1. `ARCHITECTURE.md` - System architecture overview
2. `SETUP.md` - Initial setup and prerequisites
3. `DEPLOYMENT.md` - Deployment procedures
4. `TROUBLESHOOTING.md` - Common issues and fixes
5. `COST-OPTIMIZATION.md` - Cost management tips
6. `SECURITY.md` - Security best practices

---

## 🛠️ Scripts to Create

Create in `scripts/`:
1. `create-gcs-bucket.sh` - Initialize GCS state bucket
2. `create-service-account.sh` - Create Terraform service account
3. `plan.sh` - Wrapper for terraform plan
4. `apply.sh` - Wrapper for terraform apply
5. `destroy.sh` - Wrapper for terraform destroy
6. `get-outputs.sh` - Display infrastructure outputs
7. `verify-setup.sh` - Verify setup is correct
8. `backup-state.sh` - Manual state backup
9. `restore-state.sh` - Restore state from backup
10. `cleanup.sh` - Clean up all resources

---

## ✅ Implementation Checklist

- [ ] Create directory structure
- [ ] Create all terraform files (backend, provider, variables, main, outputs)
- [ ] Create all module directories and files
- [ ] Create environment configurations (dev, staging, prod)
- [ ] Create cloudbuild.yaml for CI/CD
- [ ] Create all documentation files
- [ ] Create all utility scripts
- [ ] Set up .gitignore
- [ ] Initialize Git repository
- [ ] Test `terraform init` locally
- [ ] Test `terraform validate`
- [ ] Push to jobzy-infra repository

---

## 🚀 Next Steps After Creation

1. **Local Setup:**
   ```bash
   cd terraform
   terraform init
   terraform validate
   terraform fmt
   ```

2. **Create GCS Bucket:**
   ```bash
   ./scripts/create-gcs-bucket.sh
   ./scripts/create-service-account.sh
   ```

3. **Plan for Dev:**
   ```bash
   export TF_VAR_keycloak_admin_password="secure-password"
   terraform plan -var-file="environments/dev.tfvars"
   ```

4. **Set up Cloud Build:**
   - Connect GitHub repository
   - Create Cloud Build trigger
   - Set substitution variables

5. **Deploy:**
   ```bash
   terraform apply -var-file="environments/dev.tfvars"
   ```

---

## 📖 References

- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Kubernetes Provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs)
- [GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)
- [Kong Documentation](https://docs.konghq.com/)
- [Keycloak Documentation](https://www.keycloak.org/documentation)

---

**This guide provides everything needed to create a production-ready Terraform infrastructure repository for Jobzy!**
