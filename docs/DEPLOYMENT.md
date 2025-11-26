# Deployment Guide

This guide covers deploying infrastructure changes to different environments.

## Deployment Overview

Deployments can be done in two ways:
1. **Manual** - Using Terraform CLI locally
2. **Automated** - Using Cloud Build CI/CD pipelines

## Manual Deployment

### Prerequisites

- Terraform installed
- gcloud CLI configured
- Service account credentials set up
- Access to the GCP project

### Deploy to Development

```bash
cd terraform

# Set Keycloak admin password
export TF_VAR_keycloak_admin_password="SecurePassword123!"

# Initialize Terraform (if not done already)
terraform init

# Review the plan
terraform plan -var-file="environments/dev.tfvars"

# Apply changes
terraform apply -var-file="environments/dev.tfvars"
```

### Deploy to Staging

```bash
export TF_VAR_keycloak_admin_password="SecurePassword123!"

terraform plan -var-file="environments/staging.tfvars"
terraform apply -var-file="environments/staging.tfvars"
```

### Deploy to Production

```bash
export TF_VAR_keycloak_admin_password="SecurePassword123!"

terraform plan -var-file="environments/prod.tfvars"
terraform apply -var-file="environments/prod.tfvars"
```

## Automated Deployment (Cloud Build)

### Setup Cloud Build Triggers

1. **Connect GitHub Repository:**
   ```bash
   # In GCP Console: Cloud Build > Triggers > Connect Repository
   # Or use gcloud CLI:
   gcloud builds triggers create github \
     --repo-name=jobzy-infra \
     --repo-owner=SiavZ \
     --branch-pattern="^main$" \
     --build-config=cloudbuild/cloudbuild.yaml
   ```

2. **Store Secrets in Secret Manager:**
   ```bash
   echo -n "SecurePassword123!" | gcloud secrets create keycloak-admin-password \
     --data-file=- \
     --replication-policy="automatic"

   # Grant Cloud Build access
   gcloud secrets add-iam-policy-binding keycloak-admin-password \
     --member="serviceAccount:PROJECT_NUMBER@cloudbuild.gserviceaccount.com" \
     --role="roles/secretmanager.secretAccessor"
   ```

3. **Configure Trigger Substitutions:**
   - `_ENVIRONMENT`: prod
   - `_KEYCLOAK_ADMIN_PASSWORD`: $(cat secrets/keycloak-admin-password)

### Deployment Workflow

1. **Create Feature Branch:**
   ```bash
   git checkout -b feature/update-kong-replicas
   ```

2. **Make Changes:**
   ```bash
   # Edit terraform files
   vim terraform/environments/prod.tfvars
   ```

3. **Commit and Push:**
   ```bash
   git add .
   git commit -m "Update Kong replicas to 5 for production"
   git push origin feature/update-kong-replicas
   ```

4. **Create Pull Request:**
   - Open PR on GitHub
   - Cloud Build runs plan-only build
   - Review plan output in build logs

5. **Merge to Main:**
   - Approve and merge PR
   - Cloud Build automatically applies changes
   - Monitor build progress

## Using Helper Scripts

### Plan Script

```bash
./terraform/scripts/plan.sh dev
./terraform/scripts/plan.sh staging
./terraform/scripts/plan.sh prod
```

### Apply Script

```bash
./terraform/scripts/apply.sh dev
./terraform/scripts/apply.sh staging
./terraform/scripts/apply.sh prod
```

### Get Outputs Script

```bash
./terraform/scripts/get-outputs.sh prod
```

## Deployment Checklist

### Pre-Deployment

- [ ] Review Terraform plan output
- [ ] Check for resource deletions
- [ ] Verify variable values
- [ ] Ensure backup exists
- [ ] Notify team of deployment
- [ ] Schedule maintenance window (if needed)

### During Deployment

- [ ] Monitor Terraform progress
- [ ] Watch for errors
- [ ] Check Cloud Console for resource status
- [ ] Monitor application logs

### Post-Deployment

- [ ] Verify outputs
- [ ] Test Kong API Gateway
- [ ] Test Keycloak authentication
- [ ] Check pod status
- [ ] Verify database connections
- [ ] Run smoke tests
- [ ] Update documentation

## Rolling Back Changes

### Using Terraform

```bash
# Revert to previous state
git revert HEAD
git push origin main

# Or restore from backup
./scripts/restore-state.sh
```

### Using kubectl (for pod-level changes)

```bash
# Rollback deployment
kubectl rollout undo deployment/kong -n kong-system
kubectl rollout undo deployment/keycloak -n keycloak
```

## Updating Individual Components

### Update Kong Version

1. Edit `terraform/modules/kong/variables.tf`:
   ```hcl
   variable "kong_version" {
     default = "3.5"  # Update version
   }
   ```

2. Apply changes:
   ```bash
   terraform apply -var-file="environments/prod.tfvars"
   ```

### Update Keycloak Version

1. Edit `terraform/modules/keycloak/variables.tf`:
   ```hcl
   variable "keycloak_version" {
     default = "24.0"  # Update version
   }
   ```

2. Apply changes:
   ```bash
   terraform apply -var-file="environments/prod.tfvars"
   ```

### Scale Resources

1. Edit environment tfvars:
   ```hcl
   # terraform/environments/prod.tfvars
   kong_replicas = 5  # Increase replicas
   gke_max_nodes = 15  # Increase max nodes
   ```

2. Apply changes:
   ```bash
   terraform apply -var-file="environments/prod.tfvars"
   ```

## Emergency Procedures

### Quick Scale Up

```bash
# Scale Kong pods
kubectl scale deployment kong -n kong-system --replicas=10

# Scale Keycloak pods
kubectl scale deployment keycloak -n keycloak --replicas=5

# Scale GKE nodes
gcloud container clusters resize jobzy-production \
  --num-nodes=8 \
  --region=europe-north1
```

### Quick Scale Down

```bash
kubectl scale deployment kong -n kong-system --replicas=1
kubectl scale deployment keycloak -n keycloak --replicas=1
```

### Pause Deployments

```bash
# Pause deployment
kubectl rollout pause deployment/kong -n kong-system

# Resume deployment
kubectl rollout resume deployment/kong -n kong-system
```

## Monitoring Deployments

### Watch Pod Status

```bash
watch kubectl get pods -n kong-system
watch kubectl get pods -n keycloak
```

### View Deployment Events

```bash
kubectl get events -n kong-system --sort-by='.lastTimestamp'
kubectl get events -n keycloak --sort-by='.lastTimestamp'
```

### Check Deployment History

```bash
kubectl rollout history deployment/kong -n kong-system
kubectl rollout history deployment/keycloak -n keycloak
```

## Best Practices

1. **Always review plan output** before applying
2. **Test in dev first**, then staging, then production
3. **Use feature branches** for changes
4. **Keep main branch stable** - only deploy from main
5. **Tag releases** for easy rollback
6. **Monitor during deployment** - don't deploy and walk away
7. **Have a rollback plan** ready
8. **Deploy during low-traffic periods** for production
9. **Communicate with team** about deployments
10. **Document changes** in commit messages

## Troubleshooting Deployments

### Deployment Stuck

```bash
# Check events
kubectl describe deployment kong -n kong-system

# Check pod logs
kubectl logs -l app=kong -n kong-system

# Force restart
kubectl rollout restart deployment/kong -n kong-system
```

### Terraform Apply Fails

```bash
# Check state lock
terraform force-unlock <LOCK_ID>

# Refresh state
terraform refresh -var-file="environments/prod.tfvars"

# Re-run apply
terraform apply -var-file="environments/prod.tfvars"
```

### Cloud Build Fails

```bash
# View build logs
gcloud builds list
gcloud builds log <BUILD_ID>

# Re-trigger build
gcloud builds submit --config=cloudbuild/cloudbuild.yaml
```
