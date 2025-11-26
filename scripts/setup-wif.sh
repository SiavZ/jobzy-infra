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
PRINCIPAL="principalSet://iam.googleapis.com/${WORKLOAD_IDENTITY_PROVIDER}/attribute.repository/${GITHUB_OWNER}/${GITHUB_REPO}"

gcloud iam service-accounts add-iam-policy-binding $TERRAFORM_SA \
  --project="$PROJECT_ID" \
  --role="roles/iam.workloadIdentityUser" \
  --member="$PRINCIPAL" \
  --quiet
echo -e "${GREEN}✓ Workload Identity Binding created${NC}"

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
