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
