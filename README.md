# 🚀 Terraform AKS GitOps End-to-End Project

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-blue.svg)](https://www.terraform.io/)
[![Azure](https://img.shields.io/badge/Azure-Kubernetes_Service-0078D4)](https://azure.microsoft.com/en-us/services/kubernetes-service/)
[![ArgoCD](https://img.shields.io/badge/ArgoCD-2.8+-EF7B4D)](https://argo-cd.readthedocs.io/)

Complete production-ready infrastructure as code for deploying Azure Kubernetes Service (AKS) with GitOps using Terraform and ArgoCD.

## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Detailed Setup](#-detailed-setup)
- [Multi-Environment Deployment](#-multi-environment-deployment)
- [Usage](#-usage)
- [Verification](#-verification)
- [Troubleshooting](#-troubleshooting)
- [Clean Up](#-clean-up)

## 🎯 Overview

This project provides a complete infrastructure-as-code solution for deploying a production-ready Kubernetes platform on Azure using:

- **Azure Kubernetes Service (AKS)** with auto-scaling and advanced networking
- **ArgoCD** for GitOps continuous deployment
- **Azure Key Vault** integration for secrets management
- **Multi-environment support** (dev, test, prod)
- **3-tier application example** with React frontend, Node.js backend, and PostgreSQL database

## Architecture

### Infrastructure Components

- **AKS Cluster**: Managed Kubernetes with Azure AD integration
- **ArgoCD**: GitOps platform for application deployment
- **Azure Key Vault**: Secrets management with CSI driver integration
- **Network Policies**: Azure CNI with Calico for security
- **Monitoring**: Azure Monitor and Container Insights

### Environment Structure

```txt
.
├── dev/                     # Development environment
├── test/                    # Testing environment
├── prod/                    # Production environment
└── manifest-files/          # Kubernetes manifests for GitOps
    └── 3tire-configs/       # 3-tier application manifests
```

## Prerequisites

### Required Tools

- **Azure CLI** (>= 2.50.0)
- **Terraform** (>= 1.5.0)
- **kubectl** (>= 1.26.0) - optional for manual operations
- **Helm** (>= 3.0.0) - optional for manual operations

### Azure Requirements

- Azure subscription with Contributor role
- Service Principal with appropriate permissions
- SSH key pair (optional)

### Installation Commands

```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Optional: Install kubectl and Helm
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### Azure Authentication

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "your-subscription-id"

# Create Service Principal
az ad sp create-for-rbac \
  --name "terraform-aks-gitops" \
  --role "Contributor" \
  --scopes "/subscriptions/$(az account show --query id --output tsv)" \
  --sdk-auth
```

## Quick Start

### 1. Setup GitOps Repository

```bash
# Create GitHub repository
# Repository name: gitops-configs
# Copy manifests
cp -r manifest-files/* /path/to/gitops-configs/
cd /path/to/gitops-configs

# Update repository URL in argocd-application.yaml
sed -i 's|repoURL: https://github.com/itsBaivab/gitops-configs.git|repoURL: https://github.com/YOUR_USERNAME/gitops-configs.git|' argocd-application.yaml

# Commit and push
git add . && git commit -m "Initial commit" && git push origin main
```

### 2. Configure Environment

```bash
# Navigate to dev environment
cd dev/

# Update terraform.tfvars with your GitOps repository URL
# app_repo_url = "https://github.com/YOUR_USERNAME/gitops-configs.git"

# Initialize and deploy
terraform init
terraform plan
terraform apply -auto-approve
```

### 3. Access ArgoCD

```bash
# Get ArgoCD URL and credentials
ARGOCD_IP=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo "ArgoCD URL: http://$ARGOCD_IP"
echo "Username: admin"
echo "Password: $ARGOCD_PASSWORD"
```

## Detailed Setup

### Step 1: GitOps Repository Setup

1. **Create GitHub Repository**
   - Name: `gitops-configs`
   - Visibility: Public/Private
   - Initialize with README

2. **Copy Manifest Files**

   ```bash
   cp -r manifest-files/3tire-configs/* /path/to/gitops-configs/
   cd /path/to/gitops-configs
   ```

3. **Update Repository URL**

   ```bash
   # Update argocd-application.yaml with your repository URL
   sed -i 's|https://github.com/itsBaivab/gitops-configs.git|https://github.com/YOUR_USERNAME/gitops-configs.git|' argocd-application.yaml
   ```

4. **Commit and Push**

   ```bash
   git add . && git commit -m "Add 3-tier application manifests" && git push origin main
   ```

### Step 2: Infrastructure Deployment

```bash
# Configure authentication
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_TENANT_ID="your-tenant-id"

# Navigate to desired environment
cd dev/  # or test/ or prod/

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan deployment
terraform plan

# Apply infrastructure
terraform apply -auto-approve
```

### Step 3: Key Vault Configuration

After deployment, configure Key Vault secrets:

```bash
# Get required values
KEY_VAULT_NAME=$(terraform output -raw key_vault_name)
TENANT_ID=$(az account show --query tenantId -o tsv)
KV_CLIENT_ID=$(az aks show --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw aks_cluster_name) \
  --query "addonProfiles.azureKeyvaultSecretsProvider.identity.clientId" -o tsv)

# Update GitOps repository with Key Vault configuration
cd /path/to/gitops-configs
# Update key-vault-secrets.yaml with actual values
sed -i "s/REPLACE_WITH_KEY_VAULT_NAME/$KEY_VAULT_NAME/g" 3tire-configs/key-vault-secrets.yaml
sed -i "s/REPLACE_WITH_KUBELET_CLIENT_ID/$KV_CLIENT_ID/g" 3tire-configs/key-vault-secrets.yaml
sed -i "s/REPLACE_WITH_AZURE_TENANT_ID/$TENANT_ID/g" 3tire-configs/key-vault-secrets.yaml

# Commit changes
git add . && git commit -m "Configure Key Vault integration" && git push origin main
```

## Multi-Environment Deployment

### Environment Specifications

| Environment | Location  | VM Size         | Node Count | Auto-Scaling | Use Case            |
|-------------|-----------|-----------------|------------|--------------|---------------------|
| **Dev**     | East US   | Standard_D2s_v3 | 2          | 1-5 nodes    | Development         |
| **Test**    | East US 2 | Standard_D4s_v3 | 3          | 2-8 nodes    | Integration Testing |
| **Prod**    | West US 2 | Standard_D8s_v3 | 5          | 3-10 nodes   | Production          |

### Deployment Commands

```bash
# Development
cd dev/ && terraform init && terraform apply -auto-approve

# Testing
cd ../test/ && terraform init && terraform apply -auto-approve

# Production
cd ../prod/ && terraform init && terraform apply -auto-approve
```

## 🔧 Usage

### Access Applications

```bash
# Port forward to frontend
kubectl port-forward svc/frontend -n 3tirewebapp-dev 3000:3000

# Access at http://localhost:3000
```

### Alternative Access Methods

1. **LoadBalancer**: `kubectl patch svc frontend -n 3tirewebapp-dev -p '{"spec":{"type":"LoadBalancer"}}'`
2. **NodePort**: `kubectl patch svc frontend -n 3tirewebapp-dev -p '{"spec":{"type":"NodePort"}}'`
3. **Ingress**: Configure NGINX Ingress Controller and update `/etc/hosts`

### ArgoCD Management

```bash
# List applications
kubectl get applications -n argocd

# Force sync application
kubectl patch application 3tirewebapp-dev -n argocd --type merge \
  --patch '{"operation":{"sync":{"syncStrategy":{"force":true}}}}'
```

## ✅ Verification

### Health Checks

```bash
# Cluster status
kubectl get nodes
kubectl cluster-info

# ArgoCD components
kubectl get pods -n argocd
kubectl get svc -n argocd

# Application status
kubectl get applications -n argocd
kubectl get pods -n 3tirewebapp-dev
```

### Application Testing

```bash
# Test frontend
curl -H "Host: 3tirewebapp-dev.local" http://<INGRESS-IP>

# Test backend
kubectl port-forward svc/backend -n 3tirewebapp-dev 8080:8080
curl http://localhost:8080/health

# Test database
kubectl exec -it deployment/backend -n 3tirewebapp-dev -- \
  psql -h postgres -U postgres -d goalsdb -c "SELECT version();"
```

## 🔧 Troubleshooting

### Common Issues

1. **Terraform Authentication**

   ```bash
   az account show
   terraform init -reconfigure
   ```

2. **ArgoCD Access**

   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:80
   # Access: http://localhost:8080
   ```

3. **Application Sync Issues**

   ```bash
   kubectl describe application 3tirewebapp-dev -n argocd
   kubectl logs deployment/argocd-application-controller -n argocd
   ```

4. **Key Vault Secrets**

   ```bash
   kubectl get secretproviderclass -n 3tirewebapp-dev
   kubectl describe secretproviderclass postgres-secrets-provider -n 3tirewebapp-dev
   ```

### Logs and Debugging

```bash
# Application logs
kubectl logs deployment/frontend -n 3tirewebapp-dev --tail=50
kubectl logs deployment/backend -n 3tirewebapp-dev --tail=50
kubectl logs deployment/postgres -n 3tirewebapp-dev --tail=50

# ArgoCD logs
kubectl logs deployment/argocd-application-controller -n argocd --tail=50
```

## 🧹 Clean Up

### Remove Applications

```bash
# Delete ArgoCD applications
kubectl delete applications --all -n argocd
```

### Destroy Infrastructure

```bash
# For each environment
cd dev/ && terraform destroy -auto-approve
cd ../test/ && terraform destroy -auto-approve
cd ../prod/ && terraform destroy -auto-approve
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Setup

```bash
# Clone repository
git clone https://github.com/YOUR_USERNAME/terraform-aks-gitops.git
cd terraform-aks-gitops

# Install pre-commit hooks
pre-commit install

# Run linting
terraform fmt -recursive
terraform validate
```

---

## 🎯 Next Steps

1. **Explore ArgoCD WebUI** - Navigate through applications and sync policies
2. **Deploy Your Applications** - Add your own Git repositories
3. **Set Up Monitoring** - Configure Log Analytics and Azure Monitor
4. **Enable TLS** - Configure HTTPS for ArgoCD in production
5. **Scale to Test/Prod** - Deploy test and production environments

## 📞 Support

For issues or questions:

- Check the troubleshooting section above
- Review Terraform and kubectl logs
- Validate Azure permissions and quotas
- Ensure all prerequisites are met

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

## 🎉 Success Indicators

✅ All nodes in Ready state  
✅ ArgoCD pods running  
✅ Applications synced and healthy  
✅ 3-tier application accessible  
✅ Key Vault secrets mounted

**Your production-ready AKS GitOps platform is now deployed!**
