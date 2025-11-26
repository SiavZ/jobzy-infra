# Redis (Memorystore) Module

This module creates a Google Cloud Memorystore Redis instance with private connectivity.

## Features

- Private service access connectivity
- Configurable tier (BASIC or STANDARD_HA)
- Automated maintenance windows
- LRU eviction policy
- Redis 7.0 support

## Usage

```hcl
module "redis" {
  source = "./modules/redis"

  project_id    = "my-project"
  region        = "europe-north1"
  environment   = "prod"
  instance_name = "jobzy-prod-redis"

  size_gb       = 5
  redis_version = "7.0"
  tier          = "STANDARD_HA"

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
| instance_name | Redis instance name | string | - | yes |
| size_gb | Memory size in GB | number | 1 | no |
| tier | BASIC or STANDARD_HA | string | BASIC | no |
| redis_version | Redis version | string | 7.0 | no |
| reserved_ip_range | Reserved IP range | string | null | no |
| labels | Resource labels | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| instance_id | Redis instance ID |
| instance_name | Redis instance name |
| host | Redis host IP address |
| port | Redis port |
| current_location_id | Current location ID |
| connection_string | Redis connection string (host:port) |

## Tiers

- **BASIC**: Single node, no replication, lower cost
- **STANDARD_HA**: High availability with automatic failover, recommended for production

## Notes

- Uses private service access for secure connectivity
- Maintenance window set to Sunday 3:00 AM
- Eviction policy set to `allkeys-lru` (evict least recently used keys when memory is full)
- For production, use STANDARD_HA tier for high availability
