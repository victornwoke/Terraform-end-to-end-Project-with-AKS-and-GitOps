#!/bin/bash
set -e

# External Secrets Operator Installation Script
# This script installs and configures External Secrets Operator for Azure Key Vault integration

# Parameters passed from Terraform
RESOURCE_GROUP_NAME=$1
CLUSTER_NAME=$2
KEY_VAULT_URI=$3
KUBELET_IDENTITY_ID=$4
ENVIRONMENT=$5
POSTGRES_USERNAME_SECRET=$6
POSTGRES_PASSWORD_SECRET=$7
POSTGRES_DATABASE_SECRET=$8
POSTGRES_CONNECTION_STRING_SECRET=$9

echo "🔐 Getting AKS cluster credentials..."
az aks get-credentials --resource-group "${RESOURCE_GROUP_NAME}" --name "${CLUSTER_NAME}" --admin --overwrite-existing

echo "📦 Installing External Secrets Operator..."
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

# Install External Secrets Operator
helm upgrade --install external-secrets external-secrets/external-secrets \
  --namespace external-secrets-system \
  --create-namespace \
  --set installCRDs=true \
  --wait --timeout=300s

echo "⏳ Waiting for External Secrets Operator to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=external-secrets -n external-secrets-system --timeout=300s

echo "🏗️ Creating application namespace..."
kubectl create namespace "3tirewebapp-${ENVIRONMENT}" --dry-run=client -o yaml | kubectl apply -f -

echo "🔑 Creating SecretStore for Azure Key Vault..."
cat <<EOF | kubectl apply -f -
apiVersion: external-secrets.io/v1
kind: SecretStore
metadata:
  name: azure-keyvault-store
  namespace: 3tirewebapp-${ENVIRONMENT}
spec:
  provider:
    azurekv:
      vaultUrl: ${KEY_VAULT_URI}
      authType: ManagedIdentity
      identityId: ${KUBELET_IDENTITY_ID}
EOF

echo "🎯 Creating ExternalSecret for PostgreSQL credentials..."
cat <<EOF | kubectl apply -f -
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: postgres-credentials
  namespace: 3tirewebapp-${ENVIRONMENT}
spec:
  refreshInterval: 1m
  secretStoreRef:
    name: azure-keyvault-store
    kind: SecretStore
  target:
    name: postgres-credentials-from-kv
    creationPolicy: Owner
  data:
    - secretKey: POSTGRES_USER
      remoteRef:
        key: ${POSTGRES_USERNAME_SECRET}
    - secretKey: POSTGRES_PASSWORD
      remoteRef:
        key: ${POSTGRES_PASSWORD_SECRET}
    - secretKey: POSTGRES_DB
      remoteRef:
        key: ${POSTGRES_DATABASE_SECRET}
    - secretKey: DATABASE_URL
      remoteRef:
        key: ${POSTGRES_CONNECTION_STRING_SECRET}
EOF

echo "✅ Verifying ExternalSecret status..."
kubectl wait --for=condition=Ready externalsecret postgres-credentials -n "3tirewebapp-${ENVIRONMENT}" --timeout=300s || true

echo "🔍 Checking secret creation..."
for i in {1..30}; do
  if kubectl get secret postgres-credentials-from-kv -n "3tirewebapp-${ENVIRONMENT}" >/dev/null 2>&1; then
    echo "✅ Secret postgres-credentials-from-kv created successfully!"
    break
  else
    echo "⏳ Waiting for secret creation... (attempt $i/30)"
    sleep 10
  fi
done

echo "🎉 External Secrets Operator setup complete!"
