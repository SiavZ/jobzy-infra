# Cloud SQL Module

This module creates a Cloud SQL PostgreSQL instance with private IP and creates databases for Kong and Keycloak.

## Features

- Private IP connectivity
- Automated backups
- Point-in-time recovery (production only)
- SSL required for connections
- Separate databases for Kong and Keycloak
- Randomly generated secure passwords
- Query insights enabled
- IAM authentication enabled

## Usage

```hcl
module "cloud_sql" {
  source = "./modules/cloud-sql"

  project_id        = "my-project"
  region            = "europe-north1"
  environment       = "prod"
  instance_name     = "jobzy-prod-postgres"

  database_version  = "POSTGRES_15"
  tier              = "db-custom-2-8192"
  disk_size         = 20
  availability_type = "REGIONAL"

  labels = {
    project = "jobzy"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_id | GCP Project ID | string | - | yes |
| region | GCP Region | string | - | yes |
| environment | Environment (dev, staging, prod) | string | - | yes |
| instance_name | Cloud SQL instance name | string | - | yes |
| database_version | PostgreSQL version | string | POSTGRES_15 | no |
| tier | Cloud SQL tier | string | db-f1-micro | no |
| disk_size | Disk size in GB | number | 20 | no |
| availability_type | ZONAL or REGIONAL | string | ZONAL | no |
| labels | Resource labels | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| instance_name | Cloud SQL instance name |
| connection_name | Connection name for Cloud SQL Proxy |
| private_ip_address | Private IP address |
| kong_username | Kong database username |
| kong_password | Kong database password (sensitive) |
| keycloak_username | Keycloak database username |
| keycloak_password | Keycloak database password (sensitive) |

## Notes

- Deletion protection is enabled for production environments
- Point-in-time recovery is enabled for production
- Uses private IP only (no public IP)
- SSL is required for all connections
- Passwords are randomly generated and stored in Terraform state
