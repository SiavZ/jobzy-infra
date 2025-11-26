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
   ./terraform/scripts/plan.sh prod
   ./terraform/scripts/apply.sh prod
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

## Infrastructure Components

- **GKE Cluster** - Kubernetes cluster for microservices
- **Cloud SQL** - PostgreSQL database
- **Memorystore** - Redis cache
- **Kong Gateway** - API Gateway
- **Keycloak** - Identity and Access Management

## Environments

- **dev** - Development environment
- **staging** - Staging environment
- **prod** - Production environment

## Contributing

See [CONTRIBUTING.md](.github/CONTRIBUTING.md) for contribution guidelines.

## License

Proprietary - Jobzy Project
