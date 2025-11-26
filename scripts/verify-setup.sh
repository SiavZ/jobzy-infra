#!/bin/bash
set -e

# Verify infrastructure setup
# Usage: ./scripts/verify-setup.sh

echo "Verifying Jobzy Infrastructure Setup..."
echo ""

# Check tools
echo "Checking required tools..."
MISSING_TOOLS=()

command -v gcloud >/dev/null 2>&1 || MISSING_TOOLS+=("gcloud")
command -v kubectl >/dev/null 2>&1 || MISSING_TOOLS+=("kubectl")
command -v terraform >/dev/null 2>&1 || MISSING_TOOLS+=("terraform")

if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
  echo "✗ Missing tools: ${MISSING_TOOLS[*]}"
  exit 1
fi
echo "✓ All tools installed"

# Check gcloud auth
echo ""
echo "Checking gcloud authentication..."
if gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "@"; then
  echo "✓ Authenticated: $(gcloud auth list --filter=status:ACTIVE --format="value(account)")"
else
  echo "✗ Not authenticated"
  exit 1
fi

# Check project
echo ""
echo "Checking GCP project..."
PROJECT_ID=$(gcloud config get-value project)
if [ -z "$PROJECT_ID" ]; then
  echo "✗ No project set"
  exit 1
fi
echo "✓ Project: $PROJECT_ID"

# Check APIs
echo ""
echo "Checking required APIs..."
REQUIRED_APIS=(
  "compute.googleapis.com"
  "container.googleapis.com"
  "sqladmin.googleapis.com"
  "redis.googleapis.com"
  "servicenetworking.googleapis.com"
)

ALL_ENABLED=true
for API in "${REQUIRED_APIS[@]}"; do
  if gcloud services list --enabled --filter="name:${API}" --format="value(name)" | grep -q "${API}"; then
    echo "  ✓ ${API}"
  else
    echo "  ✗ ${API} (not enabled)"
    ALL_ENABLED=false
  fi
done

if [ "$ALL_ENABLED" = false ]; then
  echo ""
  echo "Enable missing APIs with:"
  echo "  gcloud services enable \\"
  for API in "${REQUIRED_APIS[@]}"; do
    echo "    ${API} \\"
  done
  echo ""
  exit 1
fi

# Check Terraform
echo ""
echo "Checking Terraform setup..."
if [ ! -f "terraform-key.json" ]; then
  echo "✗ terraform-key.json not found"
  echo "  Run: ./scripts/create-service-account.sh"
  exit 1
fi
echo "✓ terraform-key.json exists"

if [ ! -d "terraform/.terraform" ]; then
  echo "✗ Terraform not initialized"
  echo "  Run: cd terraform && terraform init"
  exit 1
fi
echo "✓ Terraform initialized"

# Check GCS bucket
echo ""
echo "Checking Terraform state bucket..."
BUCKET_NAME=$(grep 'bucket' terraform/backend.tf | awk -F'"' '{print $2}')
if gsutil ls -b gs://${BUCKET_NAME}/ &> /dev/null; then
  echo "✓ State bucket exists: ${BUCKET_NAME}"
else
  echo "✗ State bucket not found: ${BUCKET_NAME}"
  echo "  Run: ./scripts/create-gcs-bucket.sh"
  exit 1
fi

echo ""
echo "✓ All checks passed!"
echo ""
echo "Ready to deploy infrastructure:"
echo "  cd terraform"
echo "  terraform plan -var-file=\"environments/dev.tfvars\""
echo "  terraform apply -var-file=\"environments/dev.tfvars\""
