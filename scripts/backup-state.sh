#!/bin/bash
set -e

# Backup Terraform state
# Usage: ./scripts/backup-state.sh

BUCKET_NAME="${BUCKET_NAME:-jobzy-terraform-state-prod}"
BACKUP_DIR="terraform-state-backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/terraform-state-${TIMESTAMP}.tar.gz"

echo "Backing up Terraform state..."
echo "Bucket: ${BUCKET_NAME}"
echo ""

# Create backup directory
mkdir -p ${BACKUP_DIR}

# Download state files
echo "Downloading state files..."
mkdir -p /tmp/terraform-state-backup
gsutil -m rsync -r gs://${BUCKET_NAME}/ /tmp/terraform-state-backup/

# Create archive
echo "Creating backup archive..."
tar -czf ${BACKUP_FILE} -C /tmp terraform-state-backup

# Cleanup
rm -rf /tmp/terraform-state-backup

echo "✓ Backup created: ${BACKUP_FILE}"
echo ""
echo "Backup size: $(du -h ${BACKUP_FILE} | cut -f1)"
echo ""
echo "To restore:"
echo "  ./scripts/restore-state.sh ${BACKUP_FILE}"
