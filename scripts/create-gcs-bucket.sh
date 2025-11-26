#!/bin/bash
set -e

# Create GCS bucket for Terraform state
# Usage: ./scripts/create-gcs-bucket.sh

# Configuration
PROJECT_ID="${PROJECT_ID:-jobzy-production}"
BUCKET_NAME="${BUCKET_NAME:-jobzy-terraform-state-prod}"
LOCATION="${LOCATION:-europe-north1}"

echo "Creating GCS bucket for Terraform state..."
echo "Project: ${PROJECT_ID}"
echo "Bucket: ${BUCKET_NAME}"
echo "Location: ${LOCATION}"
echo ""

# Check if bucket already exists
if gsutil ls -b gs://${BUCKET_NAME}/ &> /dev/null; then
  echo "Bucket gs://${BUCKET_NAME}/ already exists"
else
  # Create bucket
  echo "Creating bucket..."
  gsutil mb -p ${PROJECT_ID} -c STANDARD -l ${LOCATION} gs://${BUCKET_NAME}/

  # Enable versioning
  echo "Enabling versioning..."
  gsutil versioning set on gs://${BUCKET_NAME}/

  # Set lifecycle policy to keep only 5 versions
  echo "Setting lifecycle policy..."
  cat > /tmp/lifecycle.json <<EOF
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
  gsutil lifecycle set /tmp/lifecycle.json gs://${BUCKET_NAME}/
  rm /tmp/lifecycle.json

  echo ""
  echo "✓ Bucket created successfully!"
fi

echo ""
echo "Bucket details:"
gsutil ls -L -b gs://${BUCKET_NAME}/

echo ""
echo "✓ Setup complete!"
echo ""
echo "Update terraform/backend.tf with:"
echo "  bucket = \"${BUCKET_NAME}\""
