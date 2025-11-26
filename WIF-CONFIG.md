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
- **Scope:** SiavZ/jobzy-infra repository
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
    ↓
WIF Binding → Terraform SA
    ↓
GCP Resources
```

**Security Layers:**
1. Repository owner check (SiavZ)
2. Repository name check (jobzy-infra)
3. Environment approval (GitHub environment: production)

### **What Cannot Be Done**
- ❌ PR from fork cannot deploy
- ❌ Service account cannot be used outside GitHub
- ❌ No manual key rotation needed
- ❌ No key exposure risk

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
