# Environment Configuration
environment             = "dev"                # Environment name (dev/test/prod)
location                = "eastus"             # Azure region for resource deployment
resource_group_name     = "aks-gitops-rg"      # Azure resource group name
kubernetes_cluster_name = "aks-gitops-cluster" # AKS cluster name
node_count              = 2                    # Number of worker nodes in AKS cluster
vm_size                 = "Standard_D2s_v3"    # VM size for AKS nodes
kubernetes_version      = "1.30.100"           # Kubernetes version for AKS cluster

# GitOps Configuration
gitops_repo_url  = "https://github.com/victornwoke/gitops-configs.git" # GitOps repository for infrastructure configs (reference only)
argocd_namespace = "argocd"                                          # Namespace where ArgoCD will be deployed

# Application Deployment Configuration 
app_repo_url  = "https://github.com/victornwoke/gitops-configs.git" # Repository containing your application manifests
app_repo_path = "3tire-configs"                                   # Path within app repository containing Kubernetes manifests

tags = {
  Environment = "development"
  Project     = "AKS-GitOps"
  ManagedBy   = "Terraform"
}

# Key Vault Configuration
enable_key_vault = true
key_vault_sku    = "standard"

# Database Credentials (will be stored in Key Vault)
postgres_username = "postgres"
postgres_password = "SecurePassword123!"
postgres_database = "goalsdb"
