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
    Environment = "test"
    Project     = "AKS-GitOps"
    ManagedBy   = "Terraform"
  }
}

# Key Vault Configuration
variable "enable_key_vault" {
  description = "Enable Azure Key Vault for storing sensitive data"
  type        = bool
  default     = true
}

variable "key_vault_sku" {
  description = "SKU for the Key Vault"
  type        = string
  default     = "standard"
}

# Database Configuration for Key Vault
variable "postgres_username" {
  description = "PostgreSQL username"
  type        = string
  default     = "postgres"
}

variable "postgres_database" {
  description = "PostgreSQL database name"
  type        = string
  default     = "goalsdb"
}
