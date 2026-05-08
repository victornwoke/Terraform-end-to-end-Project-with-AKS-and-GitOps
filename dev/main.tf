# Infrastructure-only configuration for initial deployment
# This prevents the "Provider produced inconsistent result" error

# Data source to get current Azure client configuration
data "azurerm_client_config" "current" {}

locals {
  resource_name_prefix = "${var.environment}-${random_string.suffix.result}"
  common_tags          = merge(var.tags, { Environment = var.environment })

  # Key Vault name with proper length restrictions (3-24 chars)
  key_vault_name = "kv-${substr(var.environment, 0, 3)}-${random_string.suffix.result}"

  # Use a deterministic node resource group name
  # This prevents circular dependencies
  infra_nodes_rg_name = "${var.kubernetes_cluster_name}-${var.environment}-nodes"
}

# Random String for Suffix
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
  numeric = true

  # Add lifecycle rule to prevent recreation
  lifecycle {
    ignore_changes = [length, special, upper, numeric]
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
    os_disk_size_gb             = 30
    vm_size                     = var.vm_size
    temporary_name_for_rotation = "tmpdefault"

    # Enable auto-scaling for better reliability
    auto_scaling_enabled = true
    min_count            = 1
    max_count            = 5
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

# ===============================
# KEY VAULT CONFIGURATION
# ===============================

# Generate secure random password for database
resource "random_password" "postgres_password" {
  count   = var.enable_key_vault ? 1 : 0
  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# Create Key Vault for storing sensitive cluster and application secrets
resource "azurerm_key_vault" "main" {
  count               = var.enable_key_vault ? 1 : 0
  name                = local.key_vault_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.key_vault_sku

  # Enable soft delete and purge protection for production-like environments
  soft_delete_retention_days = 7
  purge_protection_enabled   = false # Set to true for production

  # Access policy for the current user (Terraform operator)
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge", "Recover"
    ]

    certificate_permissions = [
      "Get", "List", "Create", "Delete", "Update", "Import"
    ]

    key_permissions = [
      "Get", "List", "Create", "Delete", "Update", "Import", "Backup", "Restore"
    ]
  }

  # Access policy for AKS cluster managed identity
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_kubernetes_cluster.main.identity[0].principal_id

    secret_permissions = [
      "Get", "List"
    ]

    certificate_permissions = [
      "Get", "List"
    ]
  }

  # Access policy for Key Vault Secrets Provider (CSI Driver)
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_kubernetes_cluster.main.key_vault_secrets_provider[0].secret_identity[0].object_id

    secret_permissions = [
      "Get", "List"
    ]

    certificate_permissions = [
      "Get", "List"
    ]
  }

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

  tags = local.common_tags
}

# ===============================
# DATABASE SECRETS
# ===============================

# Store PostgreSQL username in Key Vault
resource "azurerm_key_vault_secret" "postgres_username" {
  count        = var.enable_key_vault ? 1 : 0
  name         = "postgres-username"
  value        = var.postgres_username
  key_vault_id = azurerm_key_vault.main[0].id

  # Allow secret to be deleted immediately without soft delete protection
  content_type = "text/plain"

  lifecycle {
    # Allow deletion of secrets when infrastructure is destroyed
    prevent_destroy = false
    # Recreate if key vault or name changes
    replace_triggered_by = [azurerm_key_vault.main[0].id]
  }

  depends_on = [azurerm_key_vault.main]
}

# Store PostgreSQL password in Key Vault
resource "azurerm_key_vault_secret" "postgres_password" {
  count        = var.enable_key_vault ? 1 : 0
  name         = "postgres-password"
  value        = var.postgres_password != "" ? var.postgres_password : random_password.postgres_password[0].result
  key_vault_id = azurerm_key_vault.main[0].id

  # Allow secret to be deleted immediately without soft delete protection
  content_type = "text/plain"

  lifecycle {
    # Allow deletion of secrets when infrastructure is destroyed
    prevent_destroy = false
    # Recreate if key vault or password changes
    replace_triggered_by = [azurerm_key_vault.main[0].id]
  }

  depends_on = [azurerm_key_vault.main]
}

# Store PostgreSQL database name in Key Vault
resource "azurerm_key_vault_secret" "postgres_database" {
  count        = var.enable_key_vault ? 1 : 0
  name         = "postgres-database"
  value        = var.postgres_database
  key_vault_id = azurerm_key_vault.main[0].id

  # Allow secret to be deleted immediately without soft delete protection
  content_type = "text/plain"

  lifecycle {
    # Allow deletion of secrets when infrastructure is destroyed
    prevent_destroy = false
    # Recreate if key vault or database name changes
    replace_triggered_by = [azurerm_key_vault.main[0].id]
  }

  depends_on = [azurerm_key_vault.main]
}

# Store complete PostgreSQL connection string in Key Vault
resource "azurerm_key_vault_secret" "postgres_connection_string" {
  count        = var.enable_key_vault ? 1 : 0
  name         = "postgres-connection-string"
  value        = "postgresql://${var.postgres_username}:${var.postgres_password != "" ? var.postgres_password : random_password.postgres_password[0].result}@postgres:5432/${var.postgres_database}"
  key_vault_id = azurerm_key_vault.main[0].id

  # Allow secret to be deleted immediately without soft delete protection
  content_type = "text/plain"

  lifecycle {
    # Allow deletion of secrets when infrastructure is destroyed
    prevent_destroy = false
    # Recreate if key vault or connection parameters change
    replace_triggered_by = [azurerm_key_vault.main[0].id]
  }

  depends_on = [azurerm_key_vault.main]
}

