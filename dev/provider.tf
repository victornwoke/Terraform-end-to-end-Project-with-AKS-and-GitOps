terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.27.0" # Latest stable version with AKS fixes
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25.2"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9" # For wait resources
    }
  }
  required_version = ">= 1.5.0"
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    virtual_machine_scale_set {
      roll_instances_when_required = true
    }
  }
  use_msi = true
}

# Dynamic Kubernetes provider configuration using admin credentials
# This bypasses Azure AD authentication issues for automation scenarios
provider "kubernetes" {
  host                   = try(azurerm_kubernetes_cluster.main.kube_admin_config.0.host, "")
  client_certificate     = try(base64decode(azurerm_kubernetes_cluster.main.kube_admin_config.0.client_certificate), "")
  client_key             = try(base64decode(azurerm_kubernetes_cluster.main.kube_admin_config.0.client_key), "")
  cluster_ca_certificate = try(base64decode(azurerm_kubernetes_cluster.main.kube_admin_config.0.cluster_ca_certificate), "")
}

# Dynamic Helm provider configuration using admin credentials  
provider "helm" {
  kubernetes {
    host                   = try(azurerm_kubernetes_cluster.main.kube_admin_config.0.host, "")
    client_certificate     = try(base64decode(azurerm_kubernetes_cluster.main.kube_admin_config.0.client_certificate), "")
    client_key             = try(base64decode(azurerm_kubernetes_cluster.main.kube_admin_config.0.client_key), "")
    cluster_ca_certificate = try(base64decode(azurerm_kubernetes_cluster.main.kube_admin_config.0.cluster_ca_certificate), "")
  }
}
