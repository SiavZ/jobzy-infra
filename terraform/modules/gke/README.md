# GKE Module

This module creates a Google Kubernetes Engine (GKE) cluster with a managed node pool.

## Features

- Regional GKE cluster for high availability
- Autoscaling node pool
- Workload Identity enabled
- Auto-repair and auto-upgrade enabled
- Preemptible nodes for non-production environments

## Usage

```hcl
module "gke" {
  source = "./modules/gke"

  project_id   = "my-project"
  region       = "europe-north1"
  cluster_name = "my-cluster"
  environment  = "prod"

  num_nodes    = 3
  machine_type = "n1-standard-2"
  min_nodes    = 2
  max_nodes    = 10

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
| cluster_name | GKE Cluster name | string | - | yes |
| environment | Environment (dev, staging, prod) | string | - | yes |
| num_nodes | Initial number of nodes | number | 1 | no |
| machine_type | GKE node machine type | string | n1-standard-2 | no |
| min_nodes | Minimum nodes for autoscaling | number | 1 | no |
| max_nodes | Maximum nodes for autoscaling | number | 10 | no |
| labels | Resource labels | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_name | GKE cluster name |
| cluster_endpoint | GKE cluster endpoint |
| cluster_ca_certificate | GKE cluster CA certificate |
| cluster_location | GKE cluster location |
| node_pool_name | Node pool name |

## Notes

- Default node pool is immediately deleted after cluster creation
- Preemptible nodes are used for non-production environments to reduce costs
- Workload Identity is enabled for secure pod authentication
