#!/bin/bash
set -e

# Destroy infrastructure for environment
# Usage: ./terraform/scripts/destroy.sh <environment>

ENVIRONMENT=${1:-dev}
VALID_ENVS=("dev" "staging" "prod")

# Validate environment
if [[ ! " ${VALID_ENVS[@]} " =~ " ${ENVIRONMENT} " ]]; then
  echo "Error: Invalid environment '${ENVIRONMENT}'"
  echo "Valid environments: ${VALID_ENVS[*]}"
  exit 1
fi

# Check for Keycloak password
if [ -z "$TF_VAR_keycloak_admin_password" ]; then
  echo "Error: TF_VAR_keycloak_admin_password not set"
  echo ""
  echo "Set with:"
  echo "  export TF_VAR_keycloak_admin_password=\"YourSecurePassword\""
  exit 1
fi

echo "WARNING: This will DESTROY all infrastructure in ${ENVIRONMENT}!"
echo ""
read -p "Type '${ENVIRONMENT}' to confirm: " -r
if [[ ! $REPLY = "${ENVIRONMENT}" ]]; then
  echo "Cancelled"
  exit 0
fi

echo ""
echo "Destroying infrastructure for ${ENVIRONMENT}..."

cd "$(dirname "$0")/.."

terraform destroy \
  -var-file="environments/${ENVIRONMENT}.tfvars"

echo ""
echo "✓ Infrastructure destroyed"
