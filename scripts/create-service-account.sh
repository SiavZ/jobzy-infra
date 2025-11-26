#!/bin/bash
set -e

# Create service account for Terraform
# Usage: ./scripts/create-service-account.sh

# Configuration
PROJECT_ID="${PROJECT_ID:-jobzy-production}"
SA_NAME="${SA_NAME:-terraform-sa}"
SA_DISPLAY_NAME="Terraform Service Account"
KEY_FILE="${KEY_FILE:-terraform-key.json}"

echo "Creating service account for Terraform..."
echo "Project: ${PROJECT_ID}"
echo "Service Account: ${SA_NAME}"
echo ""

# Check if service account already exists
if gcloud iam service-accounts describe ${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com --project=${PROJECT_ID} &> /dev/null; then
  echo "Service account ${SA_NAME} already exists"
else
  # Create service account
  echo "Creating service account..."
  gcloud iam service-accounts create ${SA_NAME} \
    --display-name="${SA_DISPLAY_NAME}" \
    --project=${PROJECT_ID}

  echo "✓ Service account created"
fi

# Grant roles
echo ""
echo "Granting roles..."

ROLES=(
  "roles/editor"
  "roles/container.admin"
  "roles/compute.admin"
  "roles/iam.serviceAccountUser"
)

for ROLE in "${ROLES[@]}"; do
  echo "  - ${ROLE}"
  gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="${ROLE}" \
    --quiet
done

echo "✓ Roles granted"

# Create key
echo ""
echo "Creating service account key..."

if [ -f "${KEY_FILE}" ]; then
  echo "Key file ${KEY_FILE} already exists"
  read -p "Overwrite? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Skipping key creation"
    exit 0
  fi
fi

gcloud iam service-accounts keys create ${KEY_FILE} \
  --iam-account=${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com

echo "✓ Key created: ${KEY_FILE}"

echo ""
echo "✓ Setup complete!"
echo ""
echo "Export the following environment variable:"
echo "  export GOOGLE_APPLICATION_CREDENTIALS=\"\$(pwd)/${KEY_FILE}\""
echo ""
echo "WARNING: Keep this key file secure and do not commit it to git!"
