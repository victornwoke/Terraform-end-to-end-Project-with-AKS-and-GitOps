#!/bin/bash
set -e

# External Secrets Operator Cleanup Script
# This script removes External Secrets Operator resources during destroy

# Parameters passed from Terraform
ENVIRONMENT=$1

echo "🧹 Cleaning up External Secrets resources..."

# Delete ExternalSecret
kubectl delete externalsecret postgres-credentials -n "3tirewebapp-${ENVIRONMENT}" --ignore-not-found=true || true

# Delete SecretStore
kubectl delete secretstore azure-keyvault-store -n "3tirewebapp-${ENVIRONMENT}" --ignore-not-found=true || true

# Uninstall External Secrets Operator
helm uninstall external-secrets -n external-secrets-system || true

echo "✅ External Secrets cleanup completed!"
