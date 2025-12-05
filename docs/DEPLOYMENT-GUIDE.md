# Jobzy Platform - Comprehensive Deployment Guide

This guide walks you through deploying the complete Jobzy infrastructure on Google Cloud Platform.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Phase 1: GCP Foundation](#phase-1-gcp-foundation)
4. [Phase 2: Infrastructure Deployment](#phase-2-infrastructure-deployment)
5. [Phase 3: Platform Services](#phase-3-platform-services)
6. [Phase 4: Observability](#phase-4-observability)
7. [Phase 5: DNS & SSL](#phase-5-dns--ssl)
8. [Phase 6: Microservices](#phase-6-microservices)
9. [Environment Management](#environment-management)
10. [Troubleshooting](#troubleshooting)
11. [Cost Optimization](#cost-optimization)

---

## Prerequisites

### Required Tools

```bash
# Google Cloud SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud init

# Terraform (1.0+)
brew install terraform  # macOS
# or
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# kubectl
gcloud components install kubectl

# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### Required Access

- GCP account with billing enabled
- Owner or Editor role on the GCP project
- Domain name (jobzy.fi) with DNS access

---

## Quick Start

For experienced users, here's the quick deployment path:

```bash
# 1. Clone and navigate
cd Jobzy-infra

# 2. Run setup script
export PROJECT_ID="your-project-id"
export BILLING_ACCOUNT="your-billing-account"
./scripts/setup-gcp.sh

# 3. Deploy development environment
cd terraform
terraform init
terraform plan -var-file=environments/dev.tfvars -var="keycloak_admin_password=YourSecurePassword123!"
terraform apply -var-file=environments/dev.tfvars -var="keycloak_admin_password=YourSecurePassword123!"
```

---

## Phase 1: GCP Foundation

### Step 1.1: Run the Setup Script

The setup script automates all GCP foundation tasks:

```bash
# Set environment variables
export PROJECT_ID="jobzy-prod"
export PROJECT_NAME="Jobzy Production"
export REGION="europe-north1"
export BILLING_ACCOUNT="XXXXXX-XXXXXX-XXXXXX"  # Get from: gcloud billing accounts list
export GITHUB_ORG="your-github-org"  # Optional: for GitHub Actions WIF
export GITHUB_REPO="Jobzy-infra"

# Run setup
./scripts/setup-gcp.sh
```

The script will:
- Create/configure the GCP project
- Enable all required APIs (25+ APIs)
- Create service accounts with proper IAM roles
- Set up the Terraform state bucket with versioning
- Configure Workload Identity Federation (for GitHub Actions)
- Generate environment-specific tfvars files

### Step 1.2: Manual API Enablement (if needed)

If the script fails or you prefer manual setup:

```bash
gcloud services enable \
  compute.googleapis.com \
  container.googleapis.com \
  sqladmin.googleapis.com \
  redis.googleapis.com \
  storage.googleapis.com \
  servicenetworking.googleapis.com \
  run.googleapis.com \
  dns.googleapis.com \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  cloudresourcemanager.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com \
  secretmanager.googleapis.com \
  vpcaccess.googleapis.com
```

### Step 1.3: Verify Setup

```bash
# Check enabled APIs
gcloud services list --enabled

# Check service accounts
gcloud iam service-accounts list

# Check state bucket
gsutil ls -b gs://${PROJECT_ID}-terraform-state
```

---

## Phase 2: Infrastructure Deployment

### Step 2.1: Initialize Terraform

```bash
cd terraform

# Initialize with backend
terraform init

# Verify modules
terraform validate
```

### Step 2.2: Review the Plan

Always review before applying:

```bash
# Development environment
terraform plan \
  -var-file=environments/dev.tfvars \
  -var="keycloak_admin_password=YourSecurePassword123!" \
  -out=dev.plan

# Review the plan output carefully!
```

### Step 2.3: Deploy Development Environment First

```bash
# Apply development environment
terraform apply dev.plan

# Or interactively:
terraform apply \
  -var-file=environments/dev.tfvars \
  -var="keycloak_admin_password=YourSecurePassword123!"
```

### Step 2.4: Get Cluster Credentials

```bash
# Get kubectl credentials
gcloud container clusters get-credentials jobzy-dev --region europe-north1

# Verify connection
kubectl get nodes
kubectl get namespaces
```

### Step 2.5: Verify Core Infrastructure

```bash
# Check GKE
kubectl get nodes
kubectl top nodes

# Check Cloud SQL
gcloud sql instances list

# Check Redis
gcloud redis instances list --region=europe-north1

# Check Storage buckets
gsutil ls

# Get outputs
terraform output
```

---

## Phase 3: Platform Services

Kong and Keycloak are deployed automatically by Terraform. Verify they're running:

### Step 3.1: Verify Kong

```bash
# Check Kong pods
kubectl get pods -n kong-system

# Check Kong services
kubectl get svc -n kong-system

# Get Kong LoadBalancer IP
kubectl get svc kong-proxy -n kong-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

### Step 3.2: Verify Keycloak

```bash
# Check Keycloak pods
kubectl get pods -n keycloak

# Check Keycloak services
kubectl get svc -n keycloak

# Get Keycloak LoadBalancer IP
kubectl get svc keycloak -n keycloak -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

### Step 3.3: Access Keycloak Admin Console

```bash
# Port forward to access locally
kubectl port-forward svc/keycloak 8080:80 -n keycloak

# Access at: http://localhost:8080/admin
# Username: admin
# Password: (the keycloak_admin_password you set)
```

---

## Phase 4: Observability

### Step 4.1: Deploy Observability Stack

If `enable_observability = true` in your tfvars (default for staging/prod):

```bash
# Verify Prometheus/Grafana deployment
kubectl get pods -n monitoring

# Check services
kubectl get svc -n monitoring
```

### Step 4.2: Access Grafana

```bash
# Port forward
kubectl port-forward svc/prometheus-stack-grafana 3000:80 -n monitoring

# Access at: http://localhost:3000
# Username: admin
# Password: (the grafana_admin_password you set)
```

### Step 4.3: Deploy ELK Stack

If `enable_elk = true`:

```bash
# Verify ELK deployment
kubectl get pods -n logging

# Access Kibana
kubectl port-forward svc/kibana-kibana 5601:5601 -n logging
# Access at: http://localhost:5601
```

### Step 4.4: Deploy Service Mesh (Linkerd)

If `enable_linkerd = true`:

```bash
# Verify Linkerd deployment
kubectl get pods -n linkerd

# Check Linkerd dashboard
linkerd viz dashboard &
```

---

## Phase 5: DNS & SSL

### Step 5.1: Get LoadBalancer IPs

```bash
# Get all external IPs
echo "Kong API Gateway:"
kubectl get svc kong-proxy -n kong-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
echo ""

echo "Keycloak:"
kubectl get svc keycloak -n keycloak -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
echo ""

echo "Cloud Run Frontend URL:"
terraform output cloud_run_url
```

### Step 5.2: Configure DNS (Option A: Cloud DNS via Terraform)

Set `manage_dns = true` in your tfvars:

```hcl
# In environments/prod.tfvars
manage_dns = true
```

Then update your domain registrar to use GCP name servers:
```bash
terraform output dns_name_servers
```

### Step 5.3: Configure DNS (Option B: Cloudflare/External DNS)

Add these DNS records at your DNS provider:

| Type | Name | Value | TTL |
|------|------|-------|-----|
| A | @ | Cloud Run IP | 300 |
| A | www | Cloud Run IP | 300 |
| A | api | Kong IP | 300 |
| A | auth | Keycloak IP | 300 |

### Step 5.4: SSL Certificates

SSL is handled automatically:
- **Cloud Run**: Managed SSL (automatic)
- **Kong/Keycloak**: cert-manager with Let's Encrypt (recommended) or Cloud Load Balancer managed certs

---

## Phase 6: Microservices

### Step 6.1: Enable Custom Microservices

Uncomment and configure in `terraform/main.tf`:

```hcl
module "booking_service" {
  source = "./modules/microservice"

  service_name     = "booking-service"
  namespace        = "jobzy"
  create_namespace = true
  image_repository = "gcr.io/${var.project_id}/booking-service"
  image_tag        = "v1.0.0"
  # ... rest of configuration
}
```

### Step 6.2: Build and Push Container Images

```bash
# Configure Docker for GCR
gcloud auth configure-docker

# Build and push
cd ../Jobzy-booking-service
docker build -t gcr.io/${PROJECT_ID}/booking-service:v1.0.0 .
docker push gcr.io/${PROJECT_ID}/booking-service:v1.0.0
```

### Step 6.3: Deploy Pre-Built Platforms

For platforms like EasyAppointments, SuiteCRM, Chatwoot:

```bash
# Example: Deploy Chatwoot via Helm
helm repo add chatwoot https://chatwoot.github.io/charts
helm install chatwoot chatwoot/chatwoot \
  --namespace chatwoot \
  --create-namespace \
  --set postgresql.enabled=false \
  --set redis.enabled=false \
  --set env.POSTGRES_HOST=$(terraform output -raw postgres_private_ip) \
  --set env.REDIS_URL=redis://$(terraform output -raw redis_host):6379
```

---

## Environment Management

### Deploying to Different Environments

```bash
# Development
terraform workspace new dev || terraform workspace select dev
terraform apply -var-file=environments/dev.tfvars

# Staging
terraform workspace new staging || terraform workspace select staging
terraform apply -var-file=environments/staging.tfvars

# Production (requires approval)
terraform workspace new prod || terraform workspace select prod
terraform plan -var-file=environments/prod.tfvars -out=prod.plan
# Review carefully!
terraform apply prod.plan
```

### Destroying Environments

```bash
# CAUTION: This destroys all resources!
# Development only
terraform destroy -var-file=environments/dev.tfvars

# For production, remove deletion_protection first in Cloud SQL
# Then destroy
```

---

## Troubleshooting

### Common Issues

#### 1. API Not Enabled
```bash
# Error: googleapi: Error 403: API not enabled
gcloud services enable <api-name>.googleapis.com
```

#### 2. Quota Exceeded
```bash
# Check quotas
gcloud compute project-info describe --project=$PROJECT_ID

# Request quota increase in GCP Console
```

#### 3. VPC Peering Issues
```bash
# Check VPC peering status
gcloud compute networks peerings list

# Delete and recreate if stuck
terraform taint module.vpc.google_service_networking_connection.private_vpc_connection
terraform apply
```

#### 4. Pod Not Starting
```bash
# Check pod status
kubectl describe pod <pod-name> -n <namespace>

# Check logs
kubectl logs <pod-name> -n <namespace>

# Check events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
```

#### 5. Database Connection Issues
```bash
# Verify Cloud SQL proxy
kubectl get pods -l app=cloud-sql-proxy

# Test connection from within cluster
kubectl run mysql-client --image=mysql:8 --rm -it --restart=Never -- \
  mysql -h <private-ip> -u <user> -p
```

### Getting Help

```bash
# Terraform debug mode
TF_LOG=DEBUG terraform apply

# GCloud verbose mode
gcloud --verbosity=debug <command>

# kubectl debug
kubectl describe <resource> <name>
kubectl logs <pod-name> --previous
```

---

## Cost Optimization

### Development Environment

Keep costs low in development:

```hcl
# In dev.tfvars
gke_machine_type = "e2-medium"      # Cheaper than n1-standard
gke_min_nodes    = 1
gke_max_nodes    = 3

postgres_tier    = "db-f1-micro"    # Smallest tier
mysql_tier       = "db-f1-micro"

redis_size_gb    = 1                # Minimum

enable_observability = false        # Disable monitoring
enable_elk           = false        # Disable ELK
enable_linkerd       = false        # Disable service mesh
```

### Estimated Monthly Costs

| Environment | GKE | Cloud SQL | Redis | Storage | Total |
|-------------|-----|-----------|-------|---------|-------|
| Development | $60 | $50 | $20 | $5 | ~$135 |
| Staging | $150 | $150 | $60 | $20 | ~$380 |
| Production | $300 | $400 | $200 | $50 | ~$950 |

### Cost Saving Tips

1. **Use Preemptible/Spot VMs** for dev/staging
2. **Scale down** Cloud SQL during off-hours
3. **Use Committed Use Discounts** for production
4. **Enable autoscaling** with appropriate min/max
5. **Review and right-size** resources monthly

---

## Next Steps

After completing this deployment:

1. **Configure Keycloak Realms**
   - Create Jobzy realm
   - Configure OIDC clients for each service
   - Set up user federation if needed

2. **Configure Kong Routes**
   - Add routes for each microservice
   - Configure rate limiting
   - Set up authentication plugins

3. **Set Up CI/CD**
   - Configure GitHub Actions with WIF
   - Set up automated deployments
   - Configure branch protection rules

4. **Configure Monitoring Alerts**
   - Set up Slack/PagerDuty integration
   - Configure SLO dashboards
   - Set up on-call rotations

5. **Security Hardening**
   - Enable Binary Authorization
   - Configure Cloud Armor WAF
   - Set up VPC Service Controls

---

## Support

- **Documentation**: See `/docs` folder for detailed guides
- **Issues**: Create GitHub issues for bugs/features
- **Architecture**: See `documentation/` for system design
