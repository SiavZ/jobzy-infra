# Keycloak Module

This module deploys Keycloak (Identity and Access Management) on Kubernetes with PostgreSQL backend.

## Features

- Keycloak deployment on Kubernetes
- PostgreSQL database backend
- LoadBalancer service for external access
- Configurable replicas for high availability
- Health checks (liveness and readiness probes)
- Resource limits and requests
- Secure credential management via Kubernetes secrets
- Metrics and health endpoints enabled

## Usage

```hcl
module "keycloak" {
  source = "./modules/keycloak"

  project_id   = "my-project"
  region       = "europe-north1"
  environment  = "prod"
  cluster_name = "my-cluster"

  namespace = "keycloak"
  replicas  = 2

  db_host     = "10.0.0.10"
  db_port     = 5432
  db_name     = "keycloak"
  db_user     = "keycloak"
  db_password = "secure-password"

  redis_host = "10.0.0.20"
  redis_port = 6379

  admin_password = "admin-secure-password"
  hostname       = "auth.jobzy.fi"

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
| cluster_name | GKE Cluster name | string | - | yes |
| namespace | Kubernetes namespace | string | keycloak | no |
| replicas | Number of replicas | number | 2 | no |
| keycloak_version | Keycloak Docker version | string | 23.0 | no |
| db_host | PostgreSQL host | string | - | yes |
| db_port | PostgreSQL port | number | 5432 | no |
| db_name | PostgreSQL database name | string | keycloak | no |
| db_user | PostgreSQL username | string | - | yes |
| db_password | PostgreSQL password | string | - | yes |
| redis_host | Redis host | string | - | yes |
| redis_port | Redis port | number | 6379 | no |
| admin_password | Keycloak admin password | string | - | yes |
| hostname | Keycloak hostname | string | auth.jobzy.fi | no |
| labels | Resource labels | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| namespace | Keycloak namespace |
| service_name | Keycloak service name |
| loadbalancer_ip | Keycloak LoadBalancer IP |
| keycloak_url | Keycloak URL |
| admin_console_url | Keycloak Admin Console URL |

## Post-Deployment

Access the admin console at: `http://{hostname}/admin`

Default admin credentials:
- Username: `admin`
- Password: (value of `admin_password` variable)

## Notes

- Service is exposed via LoadBalancer
- Database credentials are stored in Kubernetes secrets
- Admin credentials are stored in Kubernetes secrets
- Default resource requests: 500m CPU, 1Gi memory
- Default resource limits: 2000m CPU, 2Gi memory
- Health and metrics endpoints are enabled
- Proxy mode is set to "edge" for use behind Kong Gateway
