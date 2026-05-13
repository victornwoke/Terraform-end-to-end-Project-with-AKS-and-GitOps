# 🚀 Terraform AKS GitOps End-to-End Project

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-blue.svg)](https://www.terraform.io/)
[![Azure](https://img.shields.io/badge/Azure-Kubernetes_Service-0078D4)](https://azure.microsoft.com/en-us/services/kubernetes-service/)
[![ArgoCD](https://img.shields.io/badge/ArgoCD-2.8+-EF7B4D)](https://argo-cd.readthedocs.io/)

Complete production-ready infrastructure as code for deploying Azure Kubernetes Service (AKS) with GitOps using Terraform and ArgoCD.

## Overview

This project provides a complete infrastructure-as-code solution for deploying a production-ready Kubernetes platform on Azure using:

- **Azure Kubernetes Service (AKS)** with auto-scaling and advanced networking
- **ArgoCD** for GitOps continuous deployment
- **Azure Key Vault** integration for secrets management
- **Multi-environment support** (dev, test, prod)
- **3-tier application example** with React frontend, Node.js backend, and PostgreSQL database

## Architecture

![Architecture](./azure_vmss_architecture.png)

### Infrastructure Components

- **AKS Cluster**: Managed Kubernetes with Azure AD integration
- **ArgoCD**: GitOps platform for application deployment
- **Azure Key Vault**: Secrets management with CSI driver integration
- **Network Policies**: Azure CNI with Calico for security
- **Monitoring**: Azure Monitor and Container Insights

### Environment Structure

```txt
.
├── dev/                     dev env
│   ├── argocd-app-manifest.yaml
│   ├── backend.tf
│   ├── backend.tf.example
│   ├── deploy-argocd-app.sh
│   ├── kubernetes-resources.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── provider.tf
│   ├── terraform.tfvars
│   ├── validate-deployment.sh
│   └── variables.tf
├── prod           #prod env
│   ├── argocd-app-manifest.yaml
│   ├── backend.tf
│   ├── backend.tf.example
│   ├── deploy-argocd-app.sh
│   ├── kubernetes-resources.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── provider.tf
│   ├── terraform.tfvars
│   └── variables.tf
├── README.md
└── test            #testing env
    ├── argocd-app-manifest.yaml
    ├── backend.tf
    ├── backend.tf.example
    ├── deploy-argocd-app.sh
    ├── kubernetes-resources.tf
    ├── main.tf
    ├── outputs.tf
    ├── provider.tf
    ├── terraform.tfvars
    └── variables.tf

```

## Prerequisites

### Essential Tools (Required)

```bash
# Install Azure CLI (Required for authentication and service principal)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install Terraform (latest) (Required to deploy infrastructure)
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

### Optional Tools (for manual management)

```bash
# Install kubectl (for manual cluster operations - Terraform handles K8s deployment)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Helm (for manual chart operations - Terraform uses Helm provider)
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

Note: Terraform automatically handles ArgoCD installation, Kubernetes resources, and application deployment via providers. You only need kubectl/helm for manual troubleshooting and verification.

### Azure Authentication & Service Principal

#### Step 1: Login to Azure

```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "your-subscription-id"

# Verify authentication
az account show
```

#### Step 2: Create Service Principal for Terraform

```bash
# Get your subscription ID
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
echo "Subscription ID: $SUBSCRIPTION_ID"

# Create service principal with Contributor role
az ad sp create-for-rbac \
  --name "terraform-aks-gitops" \
  --role "Contributor" \
  --scopes "/subscriptions/$SUBSCRIPTION_ID" \
  --sdk-auth

# Save the output - you'll need these values for Terraform authentication:
# {
#   "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
#   "clientSecret": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
#   "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
#   "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
# }
```

### Step 3: Configure Terraform Authentication

#### Option A: Environment Variables (Recommended)**

```bash
# Export service principal credentials
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_TENANT_ID="your-tenant-id"

# Verify Terraform can authenticate
terraform version
```

#### Option B: Azure CLI Authentication (Alternative)**

```bash
# If you prefer to use Azure CLI authentication instead of service principal
az login
az account set --subscription "your-subscription-id"
```

### SSH Key (Optional)

```bash
# Generate SSH key for node access (optional)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_azure -N ""
```

## Complete Recreation Guide

### CRITICAL: Follow this exact sequence for successful recreation

Before deploying ANY infrastructure, you MUST first set up your GitOps repository. ArgoCD will fail to deploy applications without access to the manifest files.

---

### Step 1: Create Your GitOps Repository (FIRST!)

#### 1.1 Create New GitHub Repository

1. **Go to GitHub.com** and create a new repository:
   - **Repository name**: `gitops-configs` (or your preferred name)
   - **Description**: "Kubernetes manifests for 3-tier application GitOps deployment"
   - **Visibility**: Public (recommended) or Private with proper access configured
   - ✅ **Initialize with README**

2. **Clone your new repository**:

   ```bash
   # Replace YOUR_USERNAME with your GitHub username
   git clone https://github.com/victornwoke/gitops-configs.git
   cd gitops-configs
   ```

#### 1.2 Copy and Push Manifest Files

```bash
# From this project's directory, copy the 3-tier application manifests
# Make sure you're in the root of this project first
cd Terraform-Full-Course-Azure/lessons/day28

# Copy all manifest files to your GitOps repository
cp -r manifest-files/* /path/to/your/gitops-configs/

# Or if you're already in the gitops-configs directory:
# cp /path/to/this/project/manifest-files/3tire-configs/* .

# Navigate to your GitOps repository
cd /path/to/your/gitops-configs

# Verify the files are copied correctly
ls -la
.
├── 3tire-configs
│   ├── argocd-application.yaml
│   ├── backend-config.yaml
│   ├── backend.yaml
│   ├── frontend-config.yaml
│   ├── frontend.yaml
│   ├── kustomization.yaml
│   ├── namespace.yaml
│   ├── postgres-config.yaml
│   ├── postgres-pvc.yaml
│   └── postgres.yaml
```

#### 1.3 Update Repository URL in Manifest Files

**CRITICAL: Update the ArgoCD application to point to YOUR repository:**

```bash
# Edit the ArgoCD application manifest
vim argocd-application.yaml

# Find this line (around line 11):
# repoURL: https://github.com/itsBaivab/gitops-configs.git

# Change it to YOUR repository:
# repoURL: https://github.com/victornwoke/gitops-configs.git

# Save and exit (:wq in vim)
```

#### 1.4 Commit and Push to Your GitOps Repository

```bash
# Add all manifest files
git add .

# Commit with a descriptive message
git commit -m "Initial commit"

# Push to GitHub
git push origin main
```

#### 1.5 Verify Your GitOps Repository

```bash
# Verify your repository is accessible
curl -s https://api.github.com/repos/victornwoke/gitops-configs
```

#### 1.6 Optional: Make Repository Private (Recommended for Production)

For enhanced security, make your GitOps repository private:

1. **Make Repository Private:**
   - Go to `https://github.com/victornwoke/gitops-configs`
   - Settings → General → Danger Zone → Change repository visibility → Private

2. **Create GitHub Personal Access Token:**
   - Go to: https://github.com/settings/tokens
   - Generate new token (classic)
   - Name: `argocd-gitops-access`
   - Scopes: `repo` (full control of private repositories)
   - Copy the token

3. **Configure ArgoCD for Private Repository:**

```bash
# Create secret with GitHub credentials
kubectl create secret generic github-repo-secret \
  --namespace argocd \
  --from-literal=username=victornwoke \
  --from-literal=password=YOUR_GITHUB_TOKEN_HERE

# Update argocd-app-manifest.yaml to include:
# spec:
#   source:
#     secretName: github-repo-secret
```

**Security Notes:**

- SSH keys are recommended over PAT for automated systems
- Regularly rotate tokens and keys
- Limit repository access to authorized personnel only

---

### 🔧 Step 2: Update Terraform Configuration Files

#### 2.1 Update Repository URLs in ALL Environment Files

**You must update ALL three environment configurations:**

```bash
# Navigate back to the project directory
cd /home/baivab/repos/Terraform-Full-Course-Azure/lessons/day28

# Update Development Environment
vim dev/terraform.tfvars
# Find line ~15: app_repo_url = "https://github.com/itsBaivab/gitops-configs.git"
# Change to:     app_repo_url = "https://github.com/victornwoke/gitops-configs.git"

# Update Test Environment  
vim test/terraform.tfvars
# Find line ~15: app_repo_url = "https://github.com/itsBaivab/gitops-configs.git"
# Change to:     app_repo_url = "https://github.com/victornwoke/gitops-configs.git"

# Update Production Environment
vim prod/terraform.tfvars  
# Find line ~15: app_repo_url = "https://github.com/itsBaivab/gitops-configs.git"
# Change to:     app_repo_url = "https://github.com/victornwoke/gitops-configs.git"
```

#### 2.2 Verify All Repository URLs Are Updated

#### 2.3 Optional: Customize Resource Names

```bash
# If you want to use custom resource group and cluster names:
# Edit each terraform.tfvars file and modify:

# resource_group_name     = "my-custom-aks-rg"
# kubernetes_cluster_name = "my-custom-aks-cluster"

# Note: Keep environment naming consistent across dev/test/prod
```

---

### Step 3: Validation Before Infrastructure Deployment

#### 3.1 Validate GitOps Repository Access

```bash
# Test that your GitOps repository is publicly accessible
curl -s https://raw.githubusercontent.com/victornwoke/gitops-configs/main/namespace.yaml

# This should return the namespace.yaml content. If you get a 404, check:
# 1. Repository name is correct
# 2. Repository is public OR you have access tokens configured
# 3. Files were pushed to the main branch
```

---

### Step 2: Configure Remote State Backend (Optional but Recommended)

```bash
# Navigate to dev environment
cd dev/

# Option A: Use local state (for testing)
# Skip this step - Terraform will use local state by default

# Option B: Configure Azure Storage Backend (for production)
# Copy the example backend configuration
cp backend.tf.example backend.tf

# Edit backend.tf with your Azure Storage Account details
# You'll need to create these resources first or use existing ones
```

**To set up Azure Storage Backend:**

```bash
# Create resource group for Terraform state
az group create --name "rg-terraform-state" --location "East US"

# Create storage account (name must be globally unique)
STORAGE_ACCOUNT_NAME="tfstate$(date +%s)"
az storage account create \
  --resource-group "rg-terraform-state" \
  --name "$STORAGE_ACCOUNT_NAME" \
  --sku "Standard_LRS" \
  --encryption-services blob

# Create storage container
az storage container create \
  --name "tfstate" \
  --account-name "$STORAGE_ACCOUNT_NAME"

# Update backend.tf with your values
echo "Update backend.tf with these values:"
echo "resource_group_name  = \"rg-terraform-state\""
echo "storage_account_name = \"$STORAGE_ACCOUNT_NAME\""
echo "container_name       = \"tfstate\""
echo "key                  = \"dev/terraform.tfstate\""
```

### Step 3: Deploy Development Environment

```bash
# Initialize Terraform (this will configure the backend if using remote state)
terraform init

# Review what will be created
terraform plan

# Deploy infrastructure (takes 5-10 minutes)
terraform apply -auto-approve
```

**What Terraform Deploys Automatically:**

> - ✅ AKS cluster with auto-scaling
> - ✅ ArgoCD installation via Helm
> - ✅ Azure AD integration and RBAC
> - ✅ Network policies and security groups
> - ✅ Sample guestbook application via GitOps

### Step 4: Configure kubectl Access

```bash
# Get cluster credentials using admin access
az aks get-credentials \
  --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw aks_cluster_name) \
  --admin \
  --overwrite-existing

# Verify cluster connectivity
kubectl get nodes
kubectl get namespaces
```

### Step 5: Verify ArgoCD Installation

```bash
# Check if ArgoCD is running
kubectl get pods -n argocd

# Check ArgoCD service
kubectl get svc -n argocd
```

## Step 6: Configure Key Vault Integration for ArgoCD Applications

**IMPORTANT**: After deploying your infrastructure, you need to update your ArgoCD application manifests with the actual Key Vault details. The infrastructure creates dynamic values that must be configured in your GitOps repository.

### 6.1 Get Key Vault Information from Terraform

```bash
# Get the Key Vault name created by Terraform
terraform output key_vault_name

# Get the Azure tenant ID
az account show --query tenantId -o tsv

# Get the Key Vault Secrets Provider managed identity client ID (CORRECT METHOD)
az aks show --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw aks_cluster_name) \
  --query "addonProfiles.azureKeyvaultSecretsProvider.identity.clientId" -o tsv

# Alternative: Get it from terraform show output
terraform show | grep -A 5 "key_vault_secrets_provider" | grep "client_id"
```

### 6.2 Update GitOps Repository with Key Vault Configuration

**Required Updates in Your GitOps Repository:**

**File: `3tire-configs/key-vault-secrets.yaml`**

```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: postgres-secrets-provider
  namespace: 3tirewebapp-dev
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "true"
    userAssignedIdentityID: "REPLACE_WITH_KUBELET_CLIENT_ID"    # ← Update this
    keyvaultName: "REPLACE_WITH_KEY_VAULT_NAME"                 # ← Update this  
    tenantId: "REPLACE_WITH_AZURE_TENANT_ID"                    # ← Update this
    objects: |
      array:
        - |
          objectName: postgres-username
          objectType: secret
          objectVersion: ""
        - |
          objectName: postgres-password
          objectType: secret
          objectVersion: ""
        - |
          objectName: postgres-database
          objectType: secret
          objectVersion: ""
        - |
          objectName: postgres-connection-string
          objectType: secret
          objectVersion: ""
  secretObjects:
  - secretName: postgres-credentials-from-kv
    type: Opaque
    data:
    - objectName: postgres-username
      key: POSTGRES_USER
    - objectName: postgres-password
      key: POSTGRES_PASSWORD
    - objectName: postgres-database
      key: POSTGRES_DB
    - objectName: postgres-connection-string
      key: DATABASE_URL
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: key-vault-config
  namespace: 3tirewebapp-dev
data:
  KEY_VAULT_NAME: "REPLACE_WITH_KEY_VAULT_NAME"                 # ← Update this
  KEY_VAULT_SECRET_POSTGRES_USERNAME: "postgres-username"
  KEY_VAULT_SECRET_POSTGRES_PASSWORD: "postgres-password"
  KEY_VAULT_SECRET_POSTGRES_DATABASE: "postgres-database"
  KEY_VAULT_SECRET_CONNECTION_STRING: "postgres-connection-string"
```

### 6.3 Automated Script for Key Vault Configuration

Create this script to automate the Key Vault configuration:

```bash
# Create update-keyvault-config.sh
cat > update-keyvault-config.sh << 'EOF'
#!/bin/bash

echo "🔐 Updating Key Vault configuration in GitOps repository..."

# Get values from Terraform
KEY_VAULT_NAME=$(terraform output -raw key_vault_name)
TENANT_ID=$(az account show --query tenantId -o tsv)

# Get Key Vault Secrets Provider managed identity client ID (CORRECT METHOD)
KV_SECRETS_PROVIDER_CLIENT_ID=$(az aks show --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw aks_cluster_name) \
  --query "addonProfiles.azureKeyvaultSecretsProvider.identity.clientId" -o tsv)

echo "📋 Configuration values:"
echo "  Key Vault Name: $KEY_VAULT_NAME"
echo "  Tenant ID: $TENANT_ID"  
echo "  Key Vault Secrets Provider Client ID: $KV_SECRETS_PROVIDER_CLIENT_ID"

# Path to your GitOps repository (update this path)
GITOPS_REPO_PATH="/path/to/your/gitops-configs"  # ← Update this path

if [ ! -d "$GITOPS_REPO_PATH" ]; then
  echo "❌ GitOps repository not found at: $GITOPS_REPO_PATH"
  echo "   Please update GITOPS_REPO_PATH in this script"
  exit 1
fi

# Update the key-vault-secrets.yaml file
KEY_VAULT_FILE="$GITOPS_REPO_PATH/3tire-configs/key-vault-secrets.yaml"

if [ -f "$KEY_VAULT_FILE" ]; then
  echo "🔄 Updating $KEY_VAULT_FILE..."
  
  # Create backup
  cp "$KEY_VAULT_FILE" "$KEY_VAULT_FILE.backup"
  
  # Replace placeholders with actual values
  sed -i "s/REPLACE_WITH_KUBELET_CLIENT_ID/$KV_SECRETS_PROVIDER_CLIENT_ID/g" "$KEY_VAULT_FILE"
  sed -i "s/REPLACE_WITH_KEY_VAULT_NAME/$KEY_VAULT_NAME/g" "$KEY_VAULT_FILE"
  sed -i "s/REPLACE_WITH_AZURE_TENANT_ID/$TENANT_ID/g" "$KEY_VAULT_FILE"
  
  echo "✅ Key Vault configuration updated successfully!"
  echo "🚀 Next steps:"
  echo "   1. Review the changes: git diff"
  echo "   2. Commit and push: git add . && git commit -m 'Update Key Vault configuration' && git push"
  echo "   3. ArgoCD will automatically sync the changes"
else
  echo "❌ Key Vault secrets file not found: $KEY_VAULT_FILE"
  echo "   Make sure your GitOps repository is properly set up"
fi
EOF

chmod +x update-keyvault-config.sh
```

### 6.4 Step-by-Step Manual Configuration

#### Step 1: Get the Required Values

```bash
# From your Terraform directory (e.g., dev/)
cd dev/

# Get Key Vault name
KEY_VAULT_NAME=$(terraform output -raw key_vault_name)
echo "Key Vault Name: $KEY_VAULT_NAME"

# Get Azure tenant ID  
TENANT_ID=$(az account show --query tenantId -o tsv)
echo "Tenant ID: $TENANT_ID"

# Get Key Vault Secrets Provider managed identity client ID (CORRECT METHOD)
KV_SECRETS_PROVIDER_CLIENT_ID=$(az aks show --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw aks_cluster_name) \
  --query "addonProfiles.azureKeyvaultSecretsProvider.identity.clientId" -o tsv)
echo "Key Vault Secrets Provider Client ID: $KV_SECRETS_PROVIDER_CLIENT_ID"
```

#### Step 2: Update Your GitOps Repository

```bash
# Navigate to your GitOps repository
cd /path/to/your/gitops-configs

# Edit the key-vault-secrets.yaml file
vim 3tire-configs/key-vault-secrets.yaml

# Replace these placeholders:
# REPLACE_WITH_KUBELET_CLIENT_ID     → Use the Key Vault Secrets Provider client ID from above
# REPLACE_WITH_KEY_VAULT_NAME        → Use the Key Vault name from above  
# REPLACE_WITH_AZURE_TENANT_ID       → Use the tenant ID from above
```

#### Step 3: Commit and Push Changes

```bash
# Review your changes
git diff

# Add and commit the changes
git add 3tire-configs/key-vault-secrets.yaml
git commit -m "Configure Key Vault integration with actual values

- Updated userAssignedIdentityID with kubelet client ID
- Updated keyvaultName with actual Key Vault name
- Updated tenantId with Azure tenant ID"

# Push to repository
git push origin main
```

#### Step 4: Verify ArgoCD Sync

```bash
# Check ArgoCD application status
kubectl get applications -n argocd

# Force sync if needed
kubectl patch application 3tirewebapp-dev -n argocd --type merge \
  --patch '{"operation":{"sync":{"syncStrategy":{"force":true}}}}'

# Verify Key Vault integration is working
kubectl get secretproviderclass -n 3tirewebapp-dev
kubectl describe secretproviderclass postgres-secrets-provider -n 3tirewebapp-dev
```

### 6.5 Troubleshooting Key Vault Issues

#### Common Issues and Solutions

*** 1. "tenantId is not set" Error**:

```bash
# Ensure tenantId is properly set in SecretProviderClass
kubectl get secretproviderclass postgres-secrets-provider -n 3tirewebapp-dev -o yaml | grep tenantId
```

**2. "Multiple user assigned identities" Error**:

```bash
# Ensure userAssignedIdentityID is specified
kubectl get secretproviderclass postgres-secrets-provider -n 3tirewebapp-dev -o yaml | grep userAssignedIdentityID
```

**3. "403 Forbidden" Key Vault Access Error**:

```bash
# Check if kubelet identity has Key Vault access
az keyvault show --name $(terraform output -raw key_vault_name) \
  --query "properties.accessPolicies[?objectId=='$(az aks show --resource-group $(terraform output -raw resource_group_name) --name $(terraform output -raw aks_cluster_name) --query "identityProfile.kubeletidentity.objectId" -o tsv)']" -o table

# If empty, the access policy is missing (this should be fixed by the updated Terraform)
```

**4. Pod Stuck in "ContainerCreating"**:

```bash
# Check pod events for CSI mount errors
kubectl describe pod -l app=postgres -n 3tirewebapp-dev

# Check CSI driver logs
kubectl logs -n kube-system -l app=secrets-store-csi-driver
```

### 6.6 Important Terraform Configuration Notes

#### Kubelet Identity Access Policy (Fixed in This Version)

**Background**: Previous versions of this Terraform configuration had a missing access policy for the kubelet identity, causing "403 Forbidden" errors when the CSI driver tried to access Key Vault secrets.

**Fix Applied**: The [`dev/main.tf`](dev/main.tf) file now includes this access policy:

```terraform
# Access policy for AKS Kubelet Identity (Node Agent Pool)
# This is needed when using userAssignedIdentityID in SecretProviderClass
access_policy {
  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id

  secret_permissions = [
    "Get", "List"
  ]
  
  certificate_permissions = [
    "Get", "List"
  ]
}
```

**Why This Matters**: When you specify `userAssignedIdentityID` in your SecretProviderClass to use the kubelet identity, that identity must have proper Key Vault access permissions. Without this access policy, the CSI driver cannot retrieve secrets from Key Vault.

**Alternative Approach**: You could also use the dedicated Key Vault Secrets Provider identity instead:

```yaml
# In SecretProviderClass, use this instead of kubelet identity:
userAssignedIdentityID: "<key-vault-secrets-provider-client-id>"
```

---

```bash
# Create validate-keyvault-integration.sh
cat > validate-keyvault-integration.sh << 'EOF'
#!/bin/bash

echo "🔍 Validating Key Vault integration..."

# Check if SecretProviderClass exists and is configured
echo "1. Checking SecretProviderClass..."
kubectl get secretproviderclass postgres-secrets-provider -n 3tirewebapp-dev > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "   ✅ SecretProviderClass exists"
  
  # Check if required fields are configured
  TENANT_ID=$(kubectl get secretproviderclass postgres-secrets-provider -n 3tirewebapp-dev -o jsonpath='{.spec.parameters.tenantId}')
  USER_ID=$(kubectl get secretproviderclass postgres-secrets-provider -n 3tirewebapp-dev -o jsonpath='{.spec.parameters.userAssignedIdentityID}')
  KV_NAME=$(kubectl get secretproviderclass postgres-secrets-provider -n 3tirewebapp-dev -o jsonpath='{.spec.parameters.keyvaultName}')
  
  if [ "$TENANT_ID" != "" ]; then echo "   ✅ Tenant ID configured: $TENANT_ID"; else echo "   ❌ Tenant ID missing"; fi
  if [ "$USER_ID" != "" ]; then echo "   ✅ User Assigned Identity ID configured: $USER_ID"; else echo "   ❌ User Assigned Identity ID missing"; fi
  if [ "$KV_NAME" != "" ]; then echo "   ✅ Key Vault name configured: $KV_NAME"; else echo "   ❌ Key Vault name missing"; fi
else
  echo "   ❌ SecretProviderClass not found"
fi

# Check if pods are running
echo "2. Checking pod status..."
kubectl get pods -n 3tirewebapp-dev --no-headers | while read line; do
  POD_NAME=$(echo $line | awk '{print $1}')
  POD_STATUS=$(echo $line | awk '{print $3}')
  if [ "$POD_STATUS" = "Running" ]; then
    echo "   ✅ $POD_NAME: $POD_STATUS"
  else
    echo "   ⚠️  $POD_NAME: $POD_STATUS"
  fi
done

# Check if Key Vault secret is created
echo "3. Checking Key Vault secret creation..."
kubectl get secret postgres-credentials-from-kv -n 3tirewebapp-dev > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "   ✅ Key Vault secret successfully synced to Kubernetes"
else
  echo "   ❌ Key Vault secret not found - CSI driver may not be working"
fi

echo "🎉 Validation complete!"
EOF

chmod +x validate-keyvault-integration.sh
```

---

## 🏢 Multi-Environment Setup

This repository provides three fully configured environments with progressive resource allocation:

### Environment Specifications

| Environment | Location  | VM Size         | Node Count | Auto-Scaling | OS Disk | Use Case              |
|-------------|-----------|-----------------|------------|--------------|---------|-----------------------|
| **Dev**     | East US   | Standard_D2s_v3 | 2          | 1-5 nodes    | 30GB    | Development & Testing |
| **Test**    | East US 2 | Standard_D4s_v3 | 3          | 2-8 nodes    | 50GB    | Integration Testing   |
| **Prod**    | West US 2 | Standard_D8s_v3 | 5          | 3-10 nodes   | 100GB   | Production Workloads  |

### Deployment Instructions

#### Deploy Development Environment

```bash
cd dev/
terraform init
terraform plan
terraform apply -auto-approve
```

#### Deploy Test Environment

```bash
cd test/
terraform init
terraform plan
terraform apply -auto-approve
```

#### Deploy Production Environment

```bash
cd prod/
terraform init
terraform plan
terraform apply -auto-approve
```

### Environment-Specific Features

#### **Development Environment**

- **Purpose**: Local development and experimentation
- **Resources**: Minimal resource allocation for cost efficiency
- **Monitoring**: Basic logging enabled
- **ArgoCD**: Single replica with standard resource limits

#### **Test Environment**

- **Purpose**: Integration testing and staging
- **Resources**: Enhanced VM sizes and node count for testing workloads
- **Monitoring**: Standard monitoring with extended log retention
- **ArgoCD**: Enhanced resource limits for better performance

#### **Production Environment**

- **Purpose**: Production workloads with high availability
- **Resources**: High-performance VMs with maximum scalability
- **Monitoring**: Full monitoring suite with 90-day log retention
- **ArgoCD**: High availability with multiple replicas and production-grade resource allocation

### Backend State Management

Each environment has its own Terraform state file:

- **Dev**: `dev/terraform.tfstate`
- **Test**: `test/terraform.tfstate`  
- **Prod**: `prod/terraform.tfstate`

Configure remote state backend for each environment using the respective `backend.tf.example`:

```bash
# For each environment
cp backend.tf.example backend.tf
# Update with your Azure Storage Account details
```

---

## 🌐 Accessing ArgoCD WebUI

### Get ArgoCD Access Information

```bash
# Get the LoadBalancer external IP
ARGOCD_IP=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "ArgoCD URL: http://$ARGOCD_IP"

# Get the admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "Username: admin"
echo "Password: $ARGOCD_PASSWORD"
```

### Access ArgoCD WebUI

1. **Open your web browser** and navigate to: `http://<EXTERNAL-IP>`

2. **Login credentials:**
   - **Username:** `admin`
   - **Password:** Use the password from the command above

3. **First-time setup:**
   - Change the default admin password
   - Explore the ArgoCD interface
   - Check the "Applications" section

### Alternative: Port Forward (if LoadBalancer IP is not available)

```bash
# Port forward ArgoCD service to localhost
kubectl port-forward svc/argocd-server -n argocd 8080:80

# Access via: http://localhost:8080
# Use same credentials as above
```

---

## Quick Application Access

### Manual Steps

```bash
# 1. Check your deployed applications
kubectl get applications -n argocd

# 2. For the 3-tier web application, start port forwarding to frontend
kubectl port-forward svc/frontend -n 3tirewebapp-dev 3000:3000

# 3. Open your browser and navigate to:
# http://localhost:3000
```

**🎉 Your 3-tier application is now accessible! This includes a React frontend, Node.js backend, and PostgreSQL database.**

---

## 📋 Application Access Summary

### Quick Access (Recommended)

```bash
# Port forward to frontend service for immediate access
kubectl port-forward svc/frontend -n 3tirewebapp-dev 3000:3000
```

### 🔗 All Access Methods for Your 3-Tier Application

| Method                 | Use Case                       | Prerequisites                         | Command/Steps                                                    | Access URL |
|------------------------|--------------------------------|---------------------------------------|------------------------------------------------------------------|
| **Port Forward**       | Development, Testing           | kubectl access                        | `kubectl port-forward svc/frontend -n 3tirewebapp-dev 3000:3000` | `http://localhost:3000`        |
| **Ingress (Built-in)** | Production-like, Domain Access | NGINX Ingress Controller + /etc/hosts | Install NGINX Ingress + configure hosts file                     | `http://3tirewebapp-dev.local` |
| **LoadBalancer**       | External Cloud Access          | Azure LoadBalancer support            | Patch service to LoadBalancer type                               | `http://<EXTERNAL-IP>:3000`    |
| **NodePort**           | Direct Node Access             | Node IP access                        | Patch service to NodePort type                                   | `http://<NODE-IP>:<NodePort>`  |

#### 🏆 Recommended Access Methods by Environment

- **Development**: Port Forward (fastest setup)
- **Testing/Staging**: Built-in Ingress (production-like)
- **Production**: Ingress with real domain + TLS
- **Demo/External**: LoadBalancer (public access)

### 🌐 Using the Built-in Ingress (Recommended for Production-like Testing)

Your manifest already includes an Ingress configuration! Here's how to use it:

#### 📋 Your Ingress Configuration

Your `frontend.yaml` manifest includes this built-in Ingress resource:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: frontend-ingress
  namespace: 3tirewebapp-dev
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - host: 3tirewebapp-dev.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend
                port:
                  number: 3000
```

**Key Features:**

- **Host**: `3tirewebapp-dev.local` (customizable domain for local testing)
- **Path**: `/` (root path routing to frontend)
- **Target Service**: `frontend` service on port `3000`
- **Ingress Class**: `nginx` (requires NGINX Ingress Controller)
- **Rewrite Target**: Root path rewriting for clean URLs
- **Path Type**: `Prefix` matching for flexible routing

#### Step 1: Install NGINX Ingress Controller

```bash
# Install NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# Wait for ingress controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

# Check ingress controller service
kubectl get svc -n ingress-nginx
```

#### Step 2: Configure Local Domain (for local testing)

```bash
# Get the ingress external IP
INGRESS_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Ingress IP: $INGRESS_IP"

# Add to /etc/hosts for local domain resolution
echo "$INGRESS_IP 3tirewebapp-dev.local" | sudo tee -a /etc/hosts

# Verify the ingress is working
kubectl get ingress -n 3tirewebapp-dev
```

#### Step 3: Access via Domain

```bash
# Open your browser to:
# http://3tirewebapp-dev.local

# Or test with curl
curl -H "Host: 3tirewebapp-dev.local" http://$INGRESS_IP
```

### 🚀 Alternative Access Methods

#### Method 1: LoadBalancer (External Cloud Access)

```bash
# Patch the frontend service to use LoadBalancer type
kubectl patch svc frontend -n 3tirewebapp-dev -p '{"spec":{"type":"LoadBalancer"}}'

# Wait for external IP assignment (may take 2-5 minutes)
echo "Waiting for external IP..."
kubectl get svc frontend -n 3tirewebapp-dev --watch

# Get the external IP and access your application
EXTERNAL_IP=$(kubectl get svc frontend -n 3tirewebapp-dev -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Access your application at: http://$EXTERNAL_IP:3000"

# To revert back to ClusterIP:
kubectl patch svc frontend -n 3tirewebapp-dev -p '{"spec":{"type":"ClusterIP"}}'
```

#### Method 2: NodePort (Direct Node Access)

```bash
# Patch the frontend service to use NodePort type
kubectl patch svc frontend -n 3tirewebapp-dev -p '{"spec":{"type":"NodePort"}}'

# Get the NodePort and Node IP
NODE_PORT=$(kubectl get svc frontend -n 3tirewebapp-dev -o jsonpath='{.spec.ports[0].nodePort}')
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}')

echo "Access your application at: http://$NODE_IP:$NODE_PORT"

# To revert back to ClusterIP:
kubectl patch svc frontend -n 3tirewebapp-dev -p '{"spec":{"type":"ClusterIP"}}'
```

### 🔍 Your 3-Tier Application Architecture

Your deployed application consists of:

#### **Frontend (React Application)**

- **Service**: `frontend` on port 3000 (ClusterIP)
- **Container**: `victornwoke/frontend:v2` (Note: Build and push your own image for this)
- **Features**: React-based web interface with Express.js proxy server
- **Ingress**: Pre-configured with domain `3tirewebapp-dev.local`
- **Health Checks**: HTTP probes on `/` endpoint with liveness/readiness checks
- **Resources**: 100m CPU request, 200m CPU limit, 128Mi-256Mi memory

#### **Backend (Node.js API)**

- **Service**: `backend` on port 8080 (ClusterIP)
- **Container**: `victornwoke/backend:latest` (Note: Build and push your own image for this)
- **Database Connection**: Connects to PostgreSQL via ConfigMap/Secret settings
- **API Endpoints**: Health check on `/health`, business logic APIs
- **Frontend Integration**: Backend URL configured as `http://backend:8080`
- **Resources**: 100m CPU request, 200m CPU limit, 128Mi-256Mi memory

#### **Database (PostgreSQL)**

- **Service**: `postgres` on port 5432 (ClusterIP)
- **Container**: `postgres:15`
- **Persistence**: Uses `postgres-pvc` persistent volume for data storage
- **Database**: `goalsdb` with user `postgres`
- **Configuration**: Environment variables managed via ConfigMaps and Secrets

### Test Your 3-Tier Application

```bash
# Method 1: Frontend Browser Testing (Recommended)
# 1. Use port forwarding: kubectl port-forward svc/frontend -n 3tirewebapp-dev 3000:3000
# 2. Open browser to: http://localhost:3000
# 3. Test the web interface functionality
# 4. Verify frontend-backend communication through UI interactions
# 5. Check database interactions via application features

# Method 2: API Testing (Backend Direct)
kubectl port-forward svc/backend -n 3tirewebapp-dev 8080:8080 &
echo "Testing backend health endpoint..."
curl -X GET http://localhost:8080/health
echo "Testing backend API endpoints..."
curl -X GET http://localhost:8080/api/goals  # or your specific API endpoints
kill %1  # Stop background port forwarding

# Method 3: Database Connection Testing (Internal)
echo "Testing database connectivity from backend pod..."
kubectl exec -it deployment/backend -n 3tirewebapp-dev -- \
  psql -h postgres -U postgres -d goalsdb -c "SELECT version();"

# Stop background port forwards
kill %1 %2
```

### Verify Application Health & Communication

```bash
# Check all pods are running and ready
kubectl get pods -n 3tirewebapp-dev
kubectl describe pods -n 3tirewebapp-dev

# Check application logs
kubectl logs deployment/frontend -n 3tirewebapp-dev --tail=50
kubectl logs deployment/backend -n 3tirewebapp-dev --tail=50
kubectl logs deployment/postgres -n 3tirewebapp-dev --tail=50

# Verify service endpoints
kubectl get endpoints -n 3tirewebapp-dev

# Test internal service communication
kubectl run debug-pod --image=curlimages/curl --rm -it --restart=Never -- \
  curl -s http://frontend.3tirewebapp-dev.svc.cluster.local:3000

kubectl run debug-pod --image=curlimages/curl --rm -it --restart=Never -- \
  curl -s http://backend.3tirewebapp-dev.svc.cluster.local:8080/health
```

## Troubleshooting Application Access

### Common Issues and Solutions**

**1. Frontend Port Forward Connection Refused**:

```bash
# Check if frontend service exists and has endpoints
kubectl get svc,endpoints frontend -n 3tirewebapp-dev

# Verify frontend pod is running and ready
kubectl get pods -l app=frontend -n 3tirewebapp-dev
kubectl logs deployment/frontend -n 3tirewebapp-dev

# Try different local port
kubectl port-forward svc/frontend -n 3tirewebapp-dev 3001:3000
```

**2. Application Shows Backend Connection Error**:

```bash
# Check backend service connectivity
kubectl get svc backend -n 3tirewebapp-dev
kubectl get pods -l app=backend -n 3tirewebapp-dev

# Verify backend configuration
kubectl describe configmap frontend-config -n 3tirewebapp-dev
kubectl describe configmap backend-config -n 3tirewebapp-dev

# Test backend API directly
kubectl port-forward svc/backend -n 3tirewebapp-dev 8080:8080 &
curl -v http://localhost:8080/health
kill %1
```

**3. Database Connection Issues**:

```bash
# Check PostgreSQL pod and service
kubectl get pods -l app=postgres -n 3tirewebapp-dev
kubectl get svc postgres -n 3tirewebapp-dev

# Check database credentials and configuration
kubectl describe secret postgres-secret -n 3tirewebapp-dev
kubectl describe configmap postgres-config -n 3tirewebapp-dev

# Test database connection from backend pod
kubectl exec -it deployment/backend -n 3tirewebapp-dev -- \
  nc -z postgres 5432 && echo "Database reachable" || echo "Database unreachable"
```

**4. Ingress Domain Not Resolving**:

```bash
# Check if ingress controller is running
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

# Verify ingress resource
kubectl get ingress -n 3tirewebapp-dev
kubectl describe ingress frontend-ingress -n 3tirewebapp-dev

# Check /etc/hosts entry
grep "3tirewebapp-dev.local" /etc/hosts

# Test with curl using Host header
curl -H "Host: 3tirewebapp-dev.local" http://<INGRESS-IP>
```

---

## Verification

### Automated Validation Script

```bash
# Run the deployment validation script
chmod +x validate-deployment.sh
./validate-deployment.sh
```

### Manual Verification Steps

```bash
# 1. Check cluster status
kubectl get nodes
kubectl cluster-info

# 2. Verify ArgoCD components
kubectl get pods -n argocd
kubectl get svc -n argocd

# 3. Check applications
kubectl get applications -n argocd

# 4. Test application access (if Goal Tracker is deployed)
kubectl get pods -n goal-tracker
kubectl get svc -n goal-tracker
```

### Health Indicators

Healthy deployment should show:

- All nodes in "Ready" state
- All ArgoCD pods "Running"
- ArgoCD LoadBalancer has external IP
- Applications show "Synced" and "Healthy" status

---

## 🔧 Troubleshooting

**Common Issues and Solutions**:

### 1. kubectl Connection Issues

```bash
# Reset kubectl configuration
az aks get-credentials --resource-group <rg-name> --name <cluster-name> --admin --overwrite-existing

# Test connectivity
kubectl get nodes --request-timeout=30s
```

### 2. ArgoCD UI Not Accessible

```bash
# Check LoadBalancer service
kubectl get svc argocd-server -n argocd

# Use port forwarding as backup
kubectl port-forward svc/argocd-server -n argocd 8080:80
# Access: http://localhost:8080
```

### 3. Terraform Apply Fails

```bash
# Check Azure authentication
az account show

# Re-initialize Terraform
terraform init -reconfigure

# Check for resource conflicts
terraform plan
```

### 4. Application Sync Issues

```bash
# Check ArgoCD application status
kubectl describe application <app-name> -n argocd

# Force sync via CLI
kubectl patch application <app-name> -n argocd --type merge --patch '{"operation":{"sync":{"syncStrategy":{"force":true}}}}'
```

---

## 🧹 Clean Up

### Remove Applications

```bash
# Delete all ArgoCD applications
kubectl delete applications --all -n argocd
```

### Remove Infrastructure

```bash
# Destroy the environment
terraform destroy -auto-approve
```

### Clean Up Resources

```bash
# Remove kubectl configuration
kubectl config delete-context <cluster-context>

# Clean up local files
rm -f ~/.kube/config.backup
```

---

## 📝 Configuration Files

### Key Configuration Files

- `terraform.tfvars` - Environment-specific variables
- `main.tf` - AKS cluster configuration
- `kubernetes-resources.tf` - ArgoCD and Kubernetes resources
- `provider.tf` - Terraform provider configuration

### Default Settings

- **Environment:** Development
- **Location:** East US
- **Node Count:** 2 (auto-scaling: 1-5)
- **VM Size:** Standard_D2s_v3
- **ArgoCD:** LoadBalancer with insecure mode (demo)

---

## 🎯 Next Steps

1. **Explore ArgoCD WebUI** - Navigate through applications and sync policies
2. **Deploy Your Applications** - Add your own Git repositories
3. **Set Up Monitoring** - Configure Log Analytics and Azure Monitor
4. **Enable TLS** - Configure HTTPS for ArgoCD in production
5. **Scale to Test/Prod** - Deploy test and production environments

---

## 📞 Support

For issues or questions:

Check the troubleshooting section above
Review Terraform and kubectl logs
Validate Azure permissions and quotas
Ensure all prerequisites are met

**🎉 Congratulations! You now have a fully functional AKS GitOps platform!**

## ⚠️ IMPORTANT: Key Vault Identity Configuration

### Common Mistake: Using Wrong Managed Identity

**CRITICAL ERROR TO AVOID:** Do **NOT** use the kubelet identity for the SecretProviderClass. This is a common mistake that causes "403 Forbidden" errors.

#### ❌ WRONG - Don't Use This Command

```bash
# This gets the kubelet identity - WRONG for SecretProviderClass
az aks show --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw aks_cluster_name) \
  --query "identityProfile.kubeletidentity.clientId" -o tsv
```

#### ✅ CORRECT - Use This Command

```bash
# This gets the Key Vault Secrets Provider identity - CORRECT for SecretProviderClass
az aks show --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw aks_cluster_name) \
  --query "addonProfiles.azureKeyvaultSecretsProvider.identity.clientId" -o tsv
```

#### Why This Matters

- **Key Vault Secrets Provider Identity**: Dedicated identity specifically for accessing Key Vault secrets
- **Kubelet Identity**: Node pool identity for general cluster operations
- **Using the wrong identity** results in access denied errors even with proper access policies
