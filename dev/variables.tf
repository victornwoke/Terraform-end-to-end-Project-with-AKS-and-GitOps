variable "environment" {
  description = "Environment name, such as 'prod', 'staging', 'dev'"
  type        = string
  default     = "dev"
}
variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "aks-gitops-rg"
}

variable "kubernetes_cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "aks-gitops-cluster"
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "Size of the Virtual Machine"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.32.5"
}

variable "gitops_repo_url" {
  description = "GitOps repository URL for ArgoCD"
  type        = string
  default     = "https://github.com/victornwoke/gitops-configs.git"
}

variable "argocd_namespace" {
  description = "Namespace for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "app_repo_url" {
  description = "Repository URL for the application to be deployed via ArgoCD"
  type        = string
  default     = "https://github.com/victornwoke/gitops-configs.git"
}

variable "app_repo_path" {
  description = "Path within the repository for the application manifests"
  type        = string
  default     = "3tire-configs"
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "development"
    Project     = "AKS-GitOps"
    ManagedBy   = "Terraform"
  }
}

# Key Vault Configuration
variable "enable_key_vault" {
  description = "Enable Key Vault for secrets management"
  type        = bool
  default     = true
}

variable "key_vault_sku" {
  description = "Key Vault SKU"
  type        = string
  default     = "standard"
}

# External Secrets Configuration
# External Secrets Configuration (using null_resource approach)
# variable "enable_external_secrets" {
#   description = "Enable External Secrets Operator for dynamic secret management"
#   type        = bool
#   default     = false
# }
# Note: External Secrets Operator is now deployed via null_resource to avoid chicken-egg problem

# Database Configuration
variable "postgres_username" {
  description = "PostgreSQL admin username"
  type        = string
  default     = "postgres"
}

variable "postgres_password" {
  description = "PostgreSQL admin password"
  type        = string
  sensitive   = true
  default     = "SecurePassword123!"
}

variable "postgres_database" {
  description = "PostgreSQL database name"
  type        = string
  default     = "goalsdb"
}
