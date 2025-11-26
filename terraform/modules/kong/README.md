# Kong Gateway Module

This module deploys Kong Gateway on Kubernetes with PostgreSQL backend.

## Features

- Kong API Gateway deployment on Kubernetes
- PostgreSQL database backend
- LoadBalancer service for external access
- Configurable replicas for high availability
- Health checks (liveness and readiness probes)
- Resource limits and requests
- Secure credential management via Kubernetes secrets

## Usage

```hcl
module "kong" {
  source = "./modules/kong"

  project_id   = "my-project"
  region       = "europe-north1"
  environment  = "prod"
  cluster_name = "my-cluster"

  namespace = "kong-system"
  replicas  = 3

  db_host     = "10.0.0.10"
  db_port     = 5432
  db_name     = "kong"
  db_user     = "kong"
  db_password = "secure-password"

  redis_host = "10.0.0.20"
  redis_port = 6379

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
| namespace | Kubernetes namespace | string | kong-system | no |
| replicas | Number of replicas | number | 3 | no |
| kong_version | Kong Docker version | string | 3.4 | no |
| db_host | PostgreSQL host | string | - | yes |
| db_port | PostgreSQL port | number | 5432 | no |
| db_name | PostgreSQL database name | string | kong | no |
| db_user | PostgreSQL username | string | - | yes |
| db_password | PostgreSQL password | string | - | yes |
| redis_host | Redis host | string | - | yes |
| redis_port | Redis port | number | 6379 | no |
| labels | Resource labels | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| namespace | Kong namespace |
| service_name | Kong proxy service name |
| loadbalancer_ip | Kong LoadBalancer IP |
| admin_service_name | Kong admin service name |
| admin_url | Kong Admin API URL (internal) |

## Post-Deployment

After deployment, run Kong migrations:

```bash
kubectl exec -it -n kong-system deployment/kong -- kong migrations bootstrap
```

## Notes

- Admin API is only accessible within the cluster (ClusterIP service)
- Proxy service is exposed via LoadBalancer
- Database credentials are stored in Kubernetes secrets
- Default resource requests: 250m CPU, 512Mi memory
- Default resource limits: 1000m CPU, 1Gi memory
