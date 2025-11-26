#!/bin/bash
set -e

# Run terraform plan for environment
# Usage: ./terraform/scripts/plan.sh <environment>

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

echo "Running Terraform plan for ${ENVIRONMENT}..."
echo ""

cd "$(dirname "$0")/.."

# Format check
echo "Checking Terraform formatting..."
terraform fmt -check -recursive || {
  echo ""
  echo "Warning: Terraform files not formatted"
  echo "Run: terraform fmt -recursive"
  echo ""
}

# Validate
echo "Validating Terraform configuration..."
terraform validate

echo ""
echo "Planning changes for ${ENVIRONMENT}..."
terraform plan \
  -var-file="environments/${ENVIRONMENT}.tfvars" \
  -out="tfplan-${ENVIRONMENT}"

echo ""
echo "✓ Plan complete!"
echo ""
echo "Review the plan above, then apply with:"
echo "  ./scripts/apply.sh ${ENVIRONMENT}"
