# Infrastructure-only configuration for initial deployment
# This prevents the "Provider produced inconsistent result" error

# Data source to get current Azure client configuration
data "azurerm_client_config" "current" {}

locals {
  resource_name_prefix = "${var.environment}-${random_string.suffix.result}"
  common_tags          = merge(var.tags, { Environment = var.environment })

  # Use a deterministic node resource group name
  # This prevents circular dependencies
  infra_nodes_rg_name = "${var.kubernetes_cluster_name}-${var.environment}-nodes"
}

# Random String for Suffix
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false

  # Add lifecycle rule to prevent recreation
  lifecycle {
    ignore_changes = [length, special, upper]
  }
}

# Resource Group with lifecycle management
resource "azurerm_resource_group" "main" {
  name     = "${var.resource_group_name}-${var.environment}"
  location = var.location
  tags     = local.common_tags

}

# AKS cluster with improved configuration
resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.kubernetes_cluster_name}-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "${var.kubernetes_cluster_name}-${var.environment}"

  # Use explicit node resource group name (this prevents circular dependencies)
  node_resource_group = local.infra_nodes_rg_name
  kubernetes_version  = var.kubernetes_version

  # Add timeouts for long operations
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }

  default_node_pool {
    name                        = "default"
    os_disk_size_gb             = 50 # Increased for test environment
    vm_size                     = var.vm_size
    temporary_name_for_rotation = "tmpdefault"

    # Enable auto-scaling for better reliability
    auto_scaling_enabled = true
    min_count            = 2 # Higher minimum for test
    max_count            = 8 # Higher maximum for test
  }

  # Conditional SSH key configuration
  dynamic "linux_profile" {
    for_each = fileexists("~/.ssh/id_rsa_azure.pub") ? [1] : []
    content {
      admin_username = "azureuser"
      ssh_key {
        key_data = file("~/.ssh/id_rsa_azure.pub")
      }
    }
  }

  identity {
    type = "SystemAssigned"
  }

  azure_active_directory_role_based_access_control {
    tenant_id          = data.azurerm_client_config.current.tenant_id
    azure_rbac_enabled = false
  }

  # Enable local accounts for admin access (required for Terraform automation)
  local_account_disabled = false

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  # Network configuration for better stability
  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
  }

  # Ignore changes to kubernetes_version to prevent unwanted upgrades
  lifecycle {
    ignore_changes = [
      kubernetes_version,
      default_node_pool[0].orchestrator_version
    ]
  }

  tags = local.common_tags
}

# Role assignment for the current user to have admin access to the cluster
resource "azurerm_role_assignment" "aks_admin" {
  scope                = azurerm_kubernetes_cluster.main.id
  role_definition_name = "Azure Kubernetes Service Cluster Admin Role"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Role assignment for the AKS managed identity to pull images from ACR (if using ACR)
# resource "azurerm_role_assignment" "aks_acr_pull" {
#   count                = 0 # Enable this if you're using ACR
#   scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
#   role_definition_name = "AcrPull"
#   principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
# }

# Role assignment for cluster managed identity to manage cluster resources
resource "azurerm_role_assignment" "aks_identity_operator" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_kubernetes_cluster.main.identity[0].principal_id
}

# Role assignment for cluster managed identity to manage network resources
resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.main.identity[0].principal_id
}

# Wait for cluster to be fully ready before proceeding with Kubernetes resources
resource "time_sleep" "wait_for_cluster" {
  depends_on = [
    azurerm_kubernetes_cluster.main,
    azurerm_role_assignment.aks_admin,
    azurerm_role_assignment.aks_identity_operator,
    azurerm_role_assignment.aks_network_contributor
  ]
  create_duration = "60s" # Wait 60 seconds for cluster and RBAC to be ready
}
