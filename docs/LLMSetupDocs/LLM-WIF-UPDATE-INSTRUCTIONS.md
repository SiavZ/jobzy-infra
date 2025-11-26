# Jobzy Infrastructure - WIF Integration for Repository

**Date:** November 26, 2025  
**Purpose:** LLM instructions to update jobzy-infra repo with Workload Identity Federation configuration

---

## 📋 Overview

This guide is for an **LLM (like Claude)** to update the jobzy-infra repository with complete Workload Identity Federation (WIF) integration. No more service account keys!

**What needs to be updated:**
1. GitHub Actions workflows (create 2 files)
2. Root documentation files (README, setup guide)
3. Terraform configuration (minimal changes - provider.tf already correct!)
4. Setup scripts (create WIF setup script)
5. Environment configuration files

---

## 🎯 Files to Create/Update

### **NEW FILES TO CREATE**

| File | Purpose |
|------|---------|
| `.github/workflows/terraform-plan.yaml` | PR trigger for terraform plan |
| `.github/workflows/terraform-apply.yaml` | Main branch trigger for terraform apply |
| `scripts/setup-wif.sh` | Automated WIF infrastructure setup |
| `WIF-CONFIG.md` | WIF configuration reference (can be committed!) |
| `GITHUB-ACTIONS-SETUP.md` | Instructions for CI/CD setup |

### **FILES TO UPDATE**

| File | Changes |
|------|---------|
| `README.md` | Add WIF note, update setup instructions |
| `.github/CONTRIBUTING.md` | Add CI/CD workflow info |

### **FILES TO VERIFY (Should already be correct)**

| File | Status |
|------|--------|
| `terraform/provider.tf` | ✅ Already correct for WIF |
| `terraform/variables.tf` | ✅ No changes needed |
| `terraform/main.tf` | ✅ No changes needed |

---

## 📝 LLM TASK 1: Create GitHub Actions Workflows

### **File: `.github/workflows/terraform-plan.yaml`**

**Purpose:** Triggered on pull requests to run `terraform plan`

```yaml
name: Terraform Plan

on:
  pull_request:
    paths:
      - 'terraform/**'
      - '.github/workflows/terraform-plan.yaml'
      - '.github/workflows/terraform-apply.yaml'
    branches:
      - main

env:
  TF_VERSION: 1.6.0

jobs:
  terraform-plan:
    runs-on: ubuntu-latest
    
    permissions:
      contents: read
      id-token: write
      pull-requests: write
    
    strategy:
      matrix:
        environment: [dev, staging]
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Set up Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: ${{ env.TF_VERSION }}
      
      - name: Authenticate to Google Cloud (WIF)
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: 'projects/${{ secrets.GCP_PROJECT_NUMBER }}/locations/global/workloadIdentityPools/github/providers/github-provider'
          service_account: 'terraform-wif@${{ secrets.GCP_PROJECT_ID }}.iam.gserviceaccount.com'
          token_format: 'access_token'
          access_token_lifetime: '3600s'
      
      - name: Set up Cloud SDK
        uses: google-github-actions/setup-gcloud@v2
      
      - name: Terraform Init
        working-directory: terraform
        run: terraform init
      
      - name: Terraform Validate
        working-directory: terraform
        run: terraform validate
      
      - name: Terraform Format Check
        working-directory: terraform
        run: terraform fmt -check -recursive
      
      - name: Terraform Plan (${{ matrix.environment }})
        working-directory: terraform
        run: |
          terraform plan \
            -var-file="environments/${{ matrix.environment }}.tfvars" \
            -out=tfplan-${{ matrix.environment }}
        env:
          TF_VAR_keycloak_admin_password: ${{ secrets.KEYCLOAK_ADMIN_PASSWORD }}
          TF_VAR_project_id: ${{ secrets.GCP_PROJECT_ID }}
          TF_VAR_region: europe-north1
      
      - name: Upload Plan Artifact
        uses: actions/upload-artifact@v4
        with:
          name: tfplan-${{ matrix.environment }}
          path: terraform/tfplan-${{ matrix.environment }}
          retention-days: 7
      
      - name: Comment PR with Plan Summary
        uses: actions/github-script@v7
        if: always()
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: '✅ Terraform plan for `${{ matrix.environment }}` completed. Check artifacts for details.'
            })
```

### **File: `.github/workflows/terraform-apply.yaml`**

**Purpose:** Triggered on main branch for production deployment

```yaml
name: Terraform Apply

on:
  push:
    branches: [main]
    paths:
      - 'terraform/**'

env:
  TF_VERSION: 1.6.0

jobs:
  terraform-apply:
    runs-on: ubuntu-latest
    environment: production  # Requires manual approval
    
    permissions:
      contents: read
      id-token: write
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Set up Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: ${{ env.TF_VERSION }}
      
      - name: Authenticate to Google Cloud (WIF)
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: 'projects/${{ secrets.GCP_PROJECT_NUMBER }}/locations/global/workloadIdentityPools/github/providers/github-provider'
          service_account: 'terraform-wif@${{ secrets.GCP_PROJECT_ID }}.iam.gserviceaccount.com'
          token_format: 'access_token'
          access_token_lifetime: '3600s'
      
      - name: Set up Cloud SDK
        uses: google-github-actions/setup-gcloud@v2
      
      - name: Terraform Init
        working-directory: terraform
        run: terraform init
      
      - name: Terraform Plan
        working-directory: terraform
        run: |
          terraform plan \
            -var-file="environments/prod.tfvars" \
            -out=tfplan-prod
        env:
          TF_VAR_keycloak_admin_password: ${{ secrets.KEYCLOAK_ADMIN_PASSWORD }}
          TF_VAR_project_id: ${{ secrets.GCP_PROJECT_ID }}
          TF_VAR_region: europe-north1
      
      - name: Terraform Apply
        working-directory: terraform
        run: terraform apply -auto-approve tfplan-prod
      
      - name: Post Deployment
        working-directory: terraform
        run: terraform output
```

---

## 📝 LLM TASK 2: Create Setup Script

### **File: `scripts/setup-wif.sh`**

**Purpose:** Automated WIF infrastructure setup (run ONCE per GCP project)

```bash
#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Jobzy Infrastructure: Workload Identity Federation Setup ===${NC}\n"

# Get configuration
read -p "Enter GCP Project ID (e.g., jobzy-production): " PROJECT_ID
read -p "Enter GitHub repository owner (e.g., SiavZ): " GITHUB_OWNER
read -p "Enter GitHub repository name (e.g., jobzy-infra): " GITHUB_REPO

export PROJECT_ID=$PROJECT_ID
export GITHUB_OWNER=$GITHUB_OWNER
export GITHUB_REPO=$GITHUB_REPO

# Validate inputs
if [ -z "$PROJECT_ID" ] || [ -z "$GITHUB_OWNER" ] || [ -z "$GITHUB_REPO" ]; then
  echo -e "${RED}Error: All inputs required${NC}"
  exit 1
fi

# Get project number
echo -e "\n${YELLOW}Getting GCP project information...${NC}"
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
echo -e "${GREEN}✓ Project Number: $PROJECT_NUMBER${NC}"

# Set project
gcloud config set project $PROJECT_ID

# Enable required APIs
echo -e "\n${YELLOW}Enabling required GCP APIs...${NC}"
gcloud services enable iam.googleapis.com
gcloud services enable iamcredentials.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable sts.googleapis.com
echo -e "${GREEN}✓ APIs enabled${NC}"

# Create Workload Identity Pool
echo -e "\n${YELLOW}Creating Workload Identity Pool...${NC}"
if gcloud iam workload-identity-pools describe github \
  --project="$PROJECT_ID" \
  --location=global &>/dev/null; then
  echo -e "${YELLOW}  (Pool already exists, skipping)${NC}"
else
  gcloud iam workload-identity-pools create "github" \
    --project="$PROJECT_ID" \
    --location="global" \
    --display-name="GitHub Actions"
  echo -e "${GREEN}✓ Workload Identity Pool created${NC}"
fi

# Create Workload Identity Provider
echo -e "\n${YELLOW}Creating Workload Identity Provider...${NC}"
if gcloud iam workload-identity-pools providers describe github-provider \
  --project="$PROJECT_ID" \
  --location=global \
  --workload-identity-pool=github &>/dev/null; then
  echo -e "${YELLOW}  (Provider already exists, skipping)${NC}"
else
  gcloud iam workload-identity-pools providers create-oidc "github-provider" \
    --project="$PROJECT_ID" \
    --location="global" \
    --workload-identity-pool="github" \
    --display-name="GitHub" \
    --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
    --issuer-uri="https://token.actions.githubusercontent.com" \
    --attribute-condition="assertion.repository_owner == '$GITHUB_OWNER'"
  echo -e "${GREEN}✓ Workload Identity Provider created${NC}"
fi

# Get provider resource name
export WORKLOAD_IDENTITY_PROVIDER=$(gcloud iam workload-identity-pools providers describe "github-provider" \
  --project="$PROJECT_ID" \
  --location="global" \
  --workload-identity-pool="github" \
  --format="value(name)")

echo -e "${GREEN}✓ Provider Resource: $WORKLOAD_IDENTITY_PROVIDER${NC}"

# Create Service Account
echo -e "\n${YELLOW}Creating Terraform service account...${NC}"
export TERRAFORM_SA="terraform-wif@${PROJECT_ID}.iam.gserviceaccount.com"

if gcloud iam service-accounts describe $TERRAFORM_SA --project="$PROJECT_ID" &>/dev/null; then
  echo -e "${YELLOW}  (Service account already exists, skipping)${NC}"
else
  gcloud iam service-accounts create terraform-wif \
    --display-name="Terraform (Workload Identity Federation)" \
    --project="$PROJECT_ID"
  echo -e "${GREEN}✓ Service account created: $TERRAFORM_SA${NC}"
fi

# Grant IAM Roles
echo -e "\n${YELLOW}Granting IAM roles to service account...${NC}"
ROLES=(
  "roles/container.admin"
  "roles/compute.admin"
  "roles/cloudsql.admin"
  "roles/redis.admin"
  "roles/storage.admin"
  "roles/iam.serviceAccountUser"
  "roles/iam.serviceAccountTokenCreator"
)

for role in "${ROLES[@]}"; do
  gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$TERRAFORM_SA" \
    --role="$role" \
    --quiet
  echo -e "${GREEN}✓ Granted $role${NC}"
done

# Create WIF Binding (main branch only - most secure)
echo -e "\n${YELLOW}Creating Workload Identity Binding...${NC}"
PRINCIPAL="principalSet://goog/subject/https:${WORKLOAD_IDENTITY_PROVIDER}:sub:repo:${GITHUB_OWNER}/${GITHUB_REPO}:ref:refs/heads/main"

gcloud iam service-accounts add-iam-policy-binding $TERRAFORM_SA \
  --project="$PROJECT_ID" \
  --role="roles/iam.workloadIdentityUser" \
  --member="$PRINCIPAL" \
  --quiet
echo -e "${GREEN}✓ Workload Identity Binding created (main branch only)${NC}"

# Display configuration
echo -e "\n${GREEN}========== WIF Setup Complete! ==========${NC}"
echo -e "\n${YELLOW}Configuration Details:${NC}"
echo "  Project ID: $PROJECT_ID"
echo "  Project Number: $PROJECT_NUMBER"
echo "  Service Account: $TERRAFORM_SA"
echo "  Workload Identity Provider: $WORKLOAD_IDENTITY_PROVIDER"

# Display GitHub Secrets required
echo -e "\n${YELLOW}Add these GitHub Secrets to your repository:${NC}"
echo "  Name: GCP_PROJECT_ID"
echo "  Value: $PROJECT_ID"
echo ""
echo "  Name: GCP_PROJECT_NUMBER"
echo "  Value: $PROJECT_NUMBER"
echo ""
echo "  Name: KEYCLOAK_ADMIN_PASSWORD"
echo "  Value: (set your secure password)"

echo -e "\n${YELLOW}Next steps:${NC}"
echo "  1. Add GitHub Secrets listed above"
echo "  2. Verify Terraform workflows run on next PR"
echo "  3. Create PR to test terraform plan"
echo "  4. Merge to main to test terraform apply"

echo -e "\n${GREEN}✓ Setup complete!${NC}\n"
```

---

## 📝 LLM TASK 3: Create WIF Configuration Reference

### **File: `WIF-CONFIG.md`**

**Purpose:** Reference for WIF configuration (safe to commit!)

```markdown
# Workload Identity Federation Configuration

**Date:** November 26, 2025  
**Status:** ✅ Configured (no service account keys!)

---

## 🔒 Architecture

No service account keys are stored anywhere. Instead:

1. **GitHub Actions** generates OIDC token signed by GitHub
2. **GCP STS** (Security Token Service) validates the token
3. **WIF binding** allows GitHub to impersonate terraform-wif service account
4. **Terraform** uses the temporary access token to provision infrastructure

**Benefits:**
- ✅ No secrets in files or environment
- ✅ Automatic token rotation (hourly)
- ✅ Full GCP audit logging
- ✅ Branch-level access control
- ✅ Industry standard (OIDC)

---

## 🏗️ Components Created

### **Workload Identity Pool**
- **Name:** github
- **Location:** global

### **Workload Identity Provider**
- **Name:** github-provider
- **Issuer URI:** https://token.actions.githubusercontent.com
- **Attribute Condition:** assertion.repository_owner == 'SiavZ'

### **Service Account**
- **Email:** terraform-wif@jobzy-production.iam.gserviceaccount.com
- **Roles:**
  - container.admin (GKE)
  - compute.admin (Compute)
  - cloudsql.admin (Cloud SQL)
  - redis.admin (Memorystore)
  - storage.admin (Cloud Storage)
  - iam.serviceAccountUser
  - iam.serviceAccountTokenCreator

### **WIF Binding**
- **Scope:** SiavZ/jobzy-infra repository, main branch only
- **Trust:** GitHub Actions OIDC tokens from specified repo

---

## 🔐 Security Model

### **Access Control**

```
GitHub Actions (any user, any workflow)
    ↓
GitHub OIDC Token
    ↓
Repository: SiavZ/jobzy-infra
Branch: main (only)
    ↓
WIF Binding → Terraform SA
    ↓
GCP Resources
```

**Security Layers:**
1. Repository owner check (SiavZ)
2. Repository name check (jobzy-infra)
3. Branch restriction (main)
4. Environment approval (GitHub environment: production)

### **What Cannot Be Done**
- ❌ PR from fork cannot deploy
- ❌ Feature branch cannot deploy to production
- ❌ Non-main branch cannot trigger apply
- ❌ Service account cannot be used outside GitHub

---

## 📊 GitHub Actions Workflows

### **terraform-plan.yaml**
- **Trigger:** Pull requests to main
- **Action:** `terraform plan` for dev and staging
- **Status:** Runs on every PR

### **terraform-apply.yaml**
- **Trigger:** Push to main
- **Action:** `terraform apply` to production
- **Status:** Requires manual GitHub environment approval

---

## 🔑 GitHub Secrets Required

Set these in GitHub Repository Settings → Secrets:

```
GCP_PROJECT_ID = jobzy-production
GCP_PROJECT_NUMBER = YOUR_PROJECT_NUMBER
KEYCLOAK_ADMIN_PASSWORD = YOUR_SECURE_PASSWORD
```

**Important:** NEVER add WORKLOAD_IDENTITY_PROVIDER or SERVICE_ACCOUNT as secrets. They're safe to commit!

---

## ✅ Verification

### **Check WIF Setup**

```bash
export PROJECT_ID="jobzy-production"

# Verify pool exists
gcloud iam workload-identity-pools describe github \
  --project=$PROJECT_ID \
  --location=global

# Verify provider exists
gcloud iam workload-identity-pools providers describe github-provider \
  --project=$PROJECT_ID \
  --location=global \
  --workload-identity-pool=github

# Verify service account exists
gcloud iam service-accounts describe \
  terraform-wif@${PROJECT_ID}.iam.gserviceaccount.com \
  --project=$PROJECT_ID

# Verify IAM binding
gcloud iam service-accounts get-iam-policy \
  terraform-wif@${PROJECT_ID}.iam.gserviceaccount.com \
  --project=$PROJECT_ID
```

### **Test GitHub Actions**

1. Create PR with Terraform changes
2. Watch GitHub Actions → Checks → Terraform Plan
3. Review plan in PR artifacts
4. Merge to main
5. Watch GitHub Actions → terraform-apply
6. Approve environment if required
7. Verify deployment

---

## 🔄 Migration Notes

This setup replaced the old service account key method:

**Before:**
- ❌ `terraform-key.json` file in repo
- ❌ Manual key rotation required
- ❌ Higher exposure risk

**After:**
- ✅ No keys stored anywhere
- ✅ Automatic token rotation
- ✅ Full audit trail
- ✅ Industry best practice

---

## 📚 References

- [Google Cloud Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
- [GitHub OIDC Token](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)

---

## 🎯 Summary

✅ **Zero service account keys**  
✅ **Automatic security rotation**  
✅ **Full audit logging**  
✅ **Production-grade security**  
✅ **GitHub Actions native integration**  

**Infrastructure secured with industry best practices!** 🔒
```

---

## 📝 LLM TASK 4: Create GitHub Actions Setup Guide

### **File: `GITHUB-ACTIONS-SETUP.md`**

```markdown
# GitHub Actions Setup Guide

---

## 🚀 Prerequisites

Before running GitHub Actions, complete WIF setup:

```bash
./scripts/setup-wif.sh
```

This creates:
- Workload Identity Pool
- Workload Identity Provider
- Service Account (no keys!)
- WIF bindings

---

## 🔑 Add GitHub Secrets

Navigate to GitHub Repository Settings → Secrets and Variables → Actions

Add these 3 secrets:

### **1. GCP_PROJECT_ID**
```
Value: jobzy-production
```

### **2. GCP_PROJECT_NUMBER**
```
Value: (from setup-wif.sh output)
```

### **3. KEYCLOAK_ADMIN_PASSWORD**
```
Value: (your secure password)
```

---

## ✅ Workflows Included

### **terraform-plan.yaml**
- Runs on: Pull requests to main
- Tests: dev and staging environments
- Action: `terraform plan` (read-only)

### **terraform-apply.yaml**
- Runs on: Push to main
- Tests: production environment
- Action: `terraform apply` (destructive!)
- Requires: Manual GitHub environment approval

---

## 🧪 Test Workflows

### **Test Plan Workflow**

```bash
# Create PR with any change
git checkout -b test/wif-plan
echo "# Test" >> README.md
git add README.md
git commit -m "test: trigger terraform plan"
git push origin test/wif-plan

# Create pull request
# → GitHub Actions runs automatically
# → Check terraform plan results in artifacts
```

### **Test Apply Workflow**

```bash
# Merge PR to main
# → terraform-apply runs
# → Requires environment approval
# → Merges to production
```

---

## 🔒 Production Safety

### **GitHub Environment Protection**

Set up production environment:

1. Go to Settings → Environments → production
2. Add required reviewers (you, team lead, etc.)
3. Set deployment branches to `main` only
4. Check "Require branch to be up to date before deployment"

This prevents accidental deployments!

---

## 📊 Monitoring

### **Workflow Runs**

View all workflow runs: Actions tab in GitHub

Check:
- ✅ Plan runs passed
- ✅ No terraform errors
- ✅ Artifacts uploaded
- ✅ Apply runs approved

### **Logs**

Click on any workflow run → Step details

View:
- Terraform init logs
- Terraform plan details
- Terraform apply output

---

## 🆘 Troubleshooting

### **Workflow Fails on Auth**

```
Error: Unable to authenticate to Google Cloud
```

**Fix:**
1. Verify WIF setup completed
2. Check GitHub secrets are set
3. Verify service account exists
4. Run: ./scripts/setup-wif.sh again

### **Terraform Init Fails**

```
Error: Backend initialization failed
```

**Fix:**
1. Verify GCS bucket exists
2. Verify service account has storage.admin role
3. Check terraform/backend.tf configuration

### **Plan Shows Unexpected Changes**

```
Plan: 100 to add, 50 to change, 10 to destroy
```

**Fix:**
1. Review terraform plan in artifacts
2. Check for state drift
3. Run `terraform refresh` locally first

---

## ✅ Success Checklist

- [ ] setup-wif.sh completed successfully
- [ ] GitHub secrets added (GCP_PROJECT_ID, GCP_PROJECT_NUMBER, KEYCLOAK_ADMIN_PASSWORD)
- [ ] PR created with test change
- [ ] terraform-plan workflow ran
- [ ] Plan artifacts available
- [ ] PR merged to main
- [ ] terraform-apply workflow triggered
- [ ] Environment approval completed
- [ ] Deployment successful
- [ ] Infrastructure updated correctly

---

**GitHub Actions + WIF = Secure, Automated Infrastructure!** 🚀
```

---

## 📝 LLM TASK 5: Update README.md

Update the root `README.md` file to reference WIF:

**Add after the Quick Start section:**

```markdown
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
```

---

## ✅ Summary of Changes

**NEW FILES (5):**
- ✅ `.github/workflows/terraform-plan.yaml`
- ✅ `.github/workflows/terraform-apply.yaml`
- ✅ `scripts/setup-wif.sh`
- ✅ `WIF-CONFIG.md`
- ✅ `GITHUB-ACTIONS-SETUP.md`

**UPDATED FILES (1):**
- ✅ `README.md` (add WIF section)

**NO CHANGES TO:**
- ✅ `terraform/provider.tf` (already correct)
- ✅ `terraform/variables.tf` (no changes needed)
- ✅ `terraform/main.tf` (no changes needed)
- ✅ All Terraform modules (no changes needed)

---

## 🚀 Execution Steps

1. **Generate all 5 new files** using this guide
2. **Update README.md** with WIF section
3. **Commit changes** to GitHub
4. **Run setup script:**
   ```bash
   chmod +x scripts/setup-wif.sh
   ./scripts/setup-wif.sh
   ```
5. **Add GitHub Secrets** (GCP_PROJECT_ID, GCP_PROJECT_NUMBER, KEYCLOAK_ADMIN_PASSWORD)
6. **Test with PR** to trigger terraform-plan workflow
7. **Merge to main** to test terraform-apply workflow

---

## 🎉 Result

**jobzy-infra repository is now WIF-configured:**
- ✅ Production-grade security
- ✅ No service account keys anywhere
- ✅ Automated CI/CD pipelines
- ✅ Full audit trail
- ✅ Enterprise-ready authentication
