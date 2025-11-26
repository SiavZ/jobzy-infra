#!/bin/bash
set -e

# Cleanup all infrastructure resources
# Usage: ./scripts/cleanup.sh <environment>

ENVIRONMENT=${1:-dev}

echo "WARNING: This will destroy ALL infrastructure in ${ENVIRONMENT}!"
echo ""
read -p "Type '${ENVIRONMENT}' to confirm: " -r
if [[ ! $REPLY = "${ENVIRONMENT}" ]]; then
  echo "Cancelled"
  exit 0
fi

echo ""
echo "Destroying infrastructure..."

cd terraform
terraform destroy -var-file="environments/${ENVIRONMENT}.tfvars"

echo ""
echo "✓ Infrastructure destroyed"
echo ""
echo "Additional cleanup (optional):"
echo "  - Delete GCS bucket: gsutil rm -r gs://jobzy-terraform-state-prod"
echo "  - Delete service account: gcloud iam service-accounts delete terraform-sa@PROJECT_ID.iam.gserviceaccount.com"
