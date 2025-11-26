# Cloud Build Configuration

This directory contains Cloud Build configurations for automated infrastructure deployment.

## Files

- `cloudbuild.yaml` - Main CI/CD pipeline (runs on main branch)
- `cloudbuild-plan.yaml` - Plan-only pipeline (for testing)
- `cloudbuild-destroy.yaml` - Destroy infrastructure (manual trigger only)

## Usage

### Setting up Cloud Build Triggers

1. **Main Deployment Trigger**
   ```bash
   gcloud builds triggers create github \
     --repo-name=jobzy-infra \
     --repo-owner=SiavZ \
     --branch-pattern="^main$" \
     --build-config=cloudbuild/cloudbuild.yaml \
     --substitutions=_ENVIRONMENT=prod,_KEYCLOAK_ADMIN_PASSWORD=<SECRET>
   ```

2. **Plan-Only Trigger (for PRs)**
   ```bash
   gcloud builds triggers create github \
     --repo-name=jobzy-infra \
     --repo-owner=SiavZ \
     --pull-request-pattern=".*" \
     --build-config=cloudbuild/cloudbuild-plan.yaml \
     --substitutions=_ENVIRONMENT=dev,_KEYCLOAK_ADMIN_PASSWORD=<SECRET>
   ```

### Manual Execution

**Run a plan:**
```bash
gcloud builds submit \
  --config=cloudbuild/cloudbuild-plan.yaml \
  --substitutions=_ENVIRONMENT=dev,_KEYCLOAK_ADMIN_PASSWORD=<PASSWORD>
```

**Run apply (on main branch):**
```bash
gcloud builds submit \
  --config=cloudbuild/cloudbuild.yaml \
  --substitutions=_ENVIRONMENT=prod,_KEYCLOAK_ADMIN_PASSWORD=<PASSWORD>
```

**Destroy infrastructure (use with extreme caution):**
```bash
gcloud builds submit \
  --config=cloudbuild/cloudbuild-destroy.yaml \
  --substitutions=_ENVIRONMENT=dev,_KEYCLOAK_ADMIN_PASSWORD=<PASSWORD>,_MANUAL_APPROVAL=approved
```

## Substitution Variables

- `_ENVIRONMENT` - Environment name (dev, staging, prod)
- `_KEYCLOAK_ADMIN_PASSWORD` - Keycloak admin password (store in Secret Manager)

## Security Best Practices

1. Store sensitive values in Google Secret Manager
2. Use least-privilege service accounts for Cloud Build
3. Enable approval gates for production deployments
4. Review all plan outputs before applying
5. Never commit passwords or secrets to the repository

## Workflow

1. Push to feature branch → No build triggered
2. Create PR → Plan-only build runs (shows what will change)
3. Merge to main → Full build with apply runs (on approval)
4. Changes are deployed automatically

## Logs

View build logs:
```bash
gcloud builds list
gcloud builds log <BUILD_ID>
```
