# Environment Configuration
environment             = "prod"               # Environment name (dev/test/prod)
location                = "eastus"             # Azure region for resource deployment
resource_group_name     = "aks-gitops-rg"      # Azure resource group name
kubernetes_cluster_name = "aks-gitops-cluster" # AKS cluster name
vm_size                 = "Standard_D8s_v3"    # VM size for AKS nodes (upgraded for production - 8 vCPUs, 32GB RAM)
kubernetes_version      = "1.32.5"             # Kubernetes version for AKS cluster

# GitOps Configuration
gitops_repo_url  = "https://github.com/victornwoke/gitops-configs.git" # GitOps repository for infrastructure configs (reference only)
argocd_namespace = "argocd"                                          # Namespace where ArgoCD will be deployed

# Application Deployment Configuration 
app_repo_url  = "https://github.com/victornwoke/gitops-configs.git" # Repository containing your application manifests
app_repo_path = "3tire-configs"                                   # Path within app repository containing Kubernetes manifests

tags = {
  Environment = "production"
  Project     = "AKS-GitOps"
  ManagedBy   = "Terraform"
}
