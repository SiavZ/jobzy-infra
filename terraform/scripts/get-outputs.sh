#!/bin/bash
set -e

# Display Terraform outputs
# Usage: ./terraform/scripts/get-outputs.sh

cd "$(dirname "$0")/.."

echo "Terraform Outputs"
echo "================="
echo ""

terraform output

echo ""
echo "To use kubectl with this cluster:"
echo "  $(terraform output -raw kubectl_context)"
echo ""
echo "Kong LoadBalancer IP:"
echo "  $(terraform output -raw kong_loadbalancer_ip 2>/dev/null || echo 'pending')"
echo ""
echo "Keycloak URL:"
echo "  $(terraform output -raw keycloak_url)"
echo ""
echo "Keycloak LoadBalancer IP:"
echo "  $(terraform output -raw keycloak_loadbalancer_ip 2>/dev/null || echo 'pending')"
