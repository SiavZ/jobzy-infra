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

## 🔐 Authentication (No Service Account Keys!)

This repository uses **Workload Identity Federation (WIF)** for secure, keyless authentication:

- ✅ No `terraform-key.json` files
- ✅ Automatic token rotation
- ✅ Full GCP audit logging
- ✅ GitHub Actions native integration

### Local Development

```bash
gcloud auth application-default login
cd terraform
terraform plan -var-file="environments/dev.tfvars"
```

### CI/CD (GitHub Actions)

See [GITHUB-ACTIONS-SETUP.md](GITHUB-ACTIONS-SETUP.md) for setup instructions.

### WIF Configuration

See [WIF-CONFIG.md](WIF-CONFIG.md) for detailed configuration reference.

---

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
