#!/bin/bash
set -e

# Apply terraform changes for environment
# Usage: ./terraform/scripts/apply.sh <environment>

ENVIRONMENT=${1:-dev}
VALID_ENVS=("dev" "staging" "prod")

# Validate environment
if [[ ! " ${VALID_ENVS[@]} " =~ " ${ENVIRONMENT} " ]]; then
  echo "Error: Invalid environment '${ENVIRONMENT}'"
  echo "Valid environments: ${VALID_ENVS[*]}"
  exit 1
fi

cd "$(dirname "$0")/.."

# Check if plan exists
if [ ! -f "tfplan-${ENVIRONMENT}" ]; then
  echo "Error: Plan file not found for ${ENVIRONMENT}"
  echo ""
  echo "Run plan first:"
  echo "  ./scripts/plan.sh ${ENVIRONMENT}"
  exit 1
fi

# Confirm for production
if [ "${ENVIRONMENT}" = "prod" ]; then
  echo "WARNING: Applying changes to PRODUCTION!"
  echo ""
  read -p "Type 'prod' to confirm: " -r
  if [[ ! $REPLY = "prod" ]]; then
    echo "Cancelled"
    exit 0
  fi
fi

echo ""
echo "Applying Terraform changes for ${ENVIRONMENT}..."
terraform apply tfplan-${ENVIRONMENT}

# Remove plan file
rm -f tfplan-${ENVIRONMENT}

echo ""
echo "✓ Apply complete!"
echo ""
echo "View outputs with:"
echo "  ./scripts/get-outputs.sh"
