#!/bin/bash
set -e

# Initialize Terraform backend
# Usage: ./terraform/scripts/init.sh

echo "Initializing Terraform..."

cd "$(dirname "$0")/.."

terraform init

echo ""
echo "✓ Terraform initialized successfully!"
echo ""
echo "Next steps:"
echo "  1. Plan: ./scripts/plan.sh dev"
echo "  2. Apply: ./scripts/apply.sh dev"
