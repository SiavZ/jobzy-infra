#!/bin/bash
set -e

# Restore Terraform state from backup
# Usage: ./scripts/restore-state.sh <backup-file>

if [ $# -eq 0 ]; then
  echo "Usage: $0 <backup-file>"
  echo ""
  echo "Available backups:"
  ls -lh terraform-state-backups/
  exit 1
fi

BACKUP_FILE=$1
BUCKET_NAME="${BUCKET_NAME:-jobzy-terraform-state-prod}"

if [ ! -f "${BACKUP_FILE}" ]; then
  echo "Error: Backup file not found: ${BACKUP_FILE}"
  exit 1
fi

echo "WARNING: This will restore Terraform state from backup!"
echo "Backup file: ${BACKUP_FILE}"
echo "Target bucket: ${BUCKET_NAME}"
echo ""
read -p "Continue? (yes/no): " -r
if [[ ! $REPLY = "yes" ]]; then
  echo "Cancelled"
  exit 0
fi

echo ""
echo "Restoring Terraform state..."

# Extract backup
echo "Extracting backup..."
tar -xzf ${BACKUP_FILE} -C /tmp/

# Upload to GCS
echo "Uploading to GCS..."
gsutil -m rsync -r /tmp/terraform-state-backup/ gs://${BUCKET_NAME}/

# Cleanup
rm -rf /tmp/terraform-state-backup

echo "✓ State restored successfully!"
echo ""
echo "Verify with:"
echo "  cd terraform && terraform plan"
