#!/bin/bash
set -e

# Script to deploy ArgoCD application
# This script is called by Terraform null_resource

echo "Deploying ArgoCD Application..."

# Get cluster credentials first
echo "🔐 Getting AKS cluster credentials..."
CLUSTER_NAME=$(terraform output -raw aks_cluster_name 2>/dev/null || echo "aks-gitops-cluster-${ENVIRONMENT}")
RESOURCE_GROUP=$(terraform output -raw resource_group_name 2>/dev/null || echo "aks-gitops-rg-${ENVIRONMENT}")

echo "📋 Cluster: $CLUSTER_NAME"
echo "📋 Resource Group: $RESOURCE_GROUP"

# Get admin credentials for the cluster
if ! az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --admin --overwrite-existing; then
    echo "❌ Failed to get cluster credentials"
    exit 1
fi

echo "✅ Cluster credentials configured"

# Verify kubectl connectivity
echo "🔍 Testing kubectl connectivity..."
if ! kubectl cluster-info --request-timeout=30s; then
    echo "❌ Cannot connect to cluster"
    exit 1
fi

# Wait for ArgoCD to be ready
echo "⏳ Waiting for ArgoCD server to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n ${ARGOCD_NAMESPACE} --timeout=300s

# Check if ArgoCD server is accessible
echo "🔍 Checking ArgoCD server accessibility..."
kubectl get pods -n ${ARGOCD_NAMESPACE} -l app.kubernetes.io/name=argocd-server

# Apply the ArgoCD application using envsubst to replace variables
echo "📝 Creating ArgoCD Application..."
envsubst < manifests/argocd-app-manifest.yaml | kubectl apply -f -

# Wait for application to be created
echo "✅ Verifying ArgoCD Application creation..."
kubectl wait --for=condition=Healthy application/3tirewebapp-${ENVIRONMENT} -n ${ARGOCD_NAMESPACE} --timeout=180s || true

# Show application status
kubectl get application 3tirewebapp-${ENVIRONMENT} -n ${ARGOCD_NAMESPACE} || true

echo "🎉 ArgoCD Application deployed successfully!"