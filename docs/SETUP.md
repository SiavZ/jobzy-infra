# Jobzy Infrastructure Setup Guide

This guide walks you through setting up the Jobzy infrastructure from scratch.

## Prerequisites

### Required Tools

1. **gcloud CLI** (Google Cloud SDK)
   ```bash
   curl https://sdk.cloud.google.com | bash
   exec -l $SHELL
   gcloud init
   ```

2. **Terraform** (v1.0+)
   ```bash
   # macOS
   brew tap hashicorp/tap
   brew install hashicorp/tap/terraform

   # Linux
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

3. **kubectl**
   ```bash
   gcloud components install kubectl
   ```

4. **git**
   ```bash
   # macOS
   brew install git

   # Linux
   sudo apt-get install git
   ```

### GCP Account Setup

1. Create a GCP account at https://console.cloud.google.com
2. Create a billing account
3. Create three projects:
   - `jobzy-dev`
   - `jobzy-staging`
   - `jobzy-production`

4. Enable required APIs for each project:
   ```bash
   gcloud config set project jobzy-dev

   gcloud services enable \
     compute.googleapis.com \
     container.googleapis.com \
     sqladmin.googleapis.com \
     redis.googleapis.com \
     servicenetworking.googleapis.com \
     cloudresourcemanager.googleapis.com
   ```

## Step 1: Clone Repository

```bash
git clone https://github.com/SiavZ/jobzy-infra.git
cd jobzy-infra
```

## Step 2: Create GCS Bucket for Terraform State

```bash
# Run the provided script
./scripts/create-gcs-bucket.sh

# Or manually:
export PROJECT_ID="jobzy-production"
export BUCKET_NAME="jobzy-terraform-state-prod"

gsutil mb -p ${PROJECT_ID} -c STANDARD -l europe-north1 gs://${BUCKET_NAME}/
gsutil versioning set on gs://${BUCKET_NAME}/
gsutil lifecycle set - gs://${BUCKET_NAME}/ <<EOF
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "Delete"},
        "condition": {"numNewerVersions": 5}
      }
    ]
  }
}
EOF
```

## Step 3: Create Service Account for Terraform

```bash
./scripts/create-service-account.sh

# Or manually:
export PROJECT_ID="jobzy-production"
export SA_NAME="terraform-sa"

gcloud iam service-accounts create ${SA_NAME} \
  --display-name="Terraform Service Account" \
  --project=${PROJECT_ID}

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/editor"

gcloud iam service-accounts keys create terraform-key.json \
  --iam-account=${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com
```

## Step 4: Configure Authentication

```bash
export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/terraform-key.json"
gcloud auth activate-service-account --key-file=terraform-key.json
```

## Step 5: Initialize Terraform

```bash
cd terraform
terraform init
```

You should see:
```
Terraform has been successfully initialized!
```

## Step 6: Validate Configuration

```bash
terraform validate
terraform fmt -check
```

## Step 7: Plan Infrastructure (Dev Environment)

```bash
export TF_VAR_keycloak_admin_password="YourSecurePassword123!"

terraform plan -var-file="environments/dev.tfvars"
```

Review the plan output carefully.

## Step 8: Deploy Infrastructure

```bash
terraform apply -var-file="environments/dev.tfvars"
```

Type `yes` when prompted.

This will take 15-30 minutes as it creates:
- GKE cluster
- Cloud SQL instance
- Redis instance
- Kong deployment
- Keycloak deployment

## Step 9: Get Cluster Credentials

```bash
gcloud container clusters get-credentials jobzy-dev --region europe-north1
```

## Step 10: Verify Deployment

```bash
# Check cluster
kubectl get nodes

# Check namespaces
kubectl get namespaces

# Check Kong
kubectl get pods -n kong-system
kubectl get svc -n kong-system

# Check Keycloak
kubectl get pods -n keycloak
kubectl get svc -n keycloak
```

## Step 11: Get Infrastructure Outputs

```bash
terraform output
```

Save these values:
- GKE cluster endpoint
- Cloud SQL connection name
- Kong LoadBalancer IP
- Keycloak LoadBalancer IP

## Step 12: Configure DNS (Optional)

Point your domain to the LoadBalancer IPs:

```
auth.jobzy.fi → Keycloak LoadBalancer IP
api.jobzy.fi → Kong LoadBalancer IP
```

## Step 13: Run Kong Migrations

```bash
kubectl exec -it -n kong-system deployment/kong -- kong migrations bootstrap
```

## Step 14: Access Services

**Keycloak Admin Console:**
```bash
KEYCLOAK_IP=$(kubectl get svc keycloak -n keycloak -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Keycloak: http://${KEYCLOAK_IP}/admin"
```

Default credentials:
- Username: `admin`
- Password: (value of `TF_VAR_keycloak_admin_password`)

**Kong Admin API:**
```bash
kubectl port-forward -n kong-system svc/kong-admin 8001:8001
curl http://localhost:8001/
```

## Troubleshooting

### Issue: Terraform init fails

**Solution:**
```bash
# Check GCS bucket exists
gsutil ls gs://jobzy-terraform-state-prod/

# Check credentials
gcloud auth list
```

### Issue: GKE cluster creation fails

**Solution:**
- Verify APIs are enabled
- Check quota limits in GCP console
- Ensure service account has correct permissions

### Issue: Pods not starting

**Solution:**
```bash
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
```

### Issue: Cannot connect to Cloud SQL

**Solution:**
- Verify private service connection exists
- Check VPC peering
- Ensure database users are created

## Next Steps

1. Configure Kong routes and services
2. Set up Keycloak realms and clients
3. Deploy microservices
4. Configure monitoring and alerting
5. Set up CI/CD pipelines

## Clean Up (Development Only)

To destroy all infrastructure:

```bash
terraform destroy -var-file="environments/dev.tfvars"
```

**WARNING:** This will delete all resources. Use with caution!

## Additional Resources

- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Kong Documentation](https://docs.konghq.com/)
- [Keycloak Documentation](https://www.keycloak.org/documentation)
