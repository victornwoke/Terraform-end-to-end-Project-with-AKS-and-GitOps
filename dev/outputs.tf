# outputs.tf
output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "aks_cluster_id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.id
}

output "kube_config" {
  description = "Kubeconfig for the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}


output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

# ===============================
# KEY VAULT OUTPUTS
# ===============================

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = var.enable_key_vault ? azurerm_key_vault.main[0].name : null
}

output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = var.enable_key_vault ? azurerm_key_vault.main[0].id : null
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = var.enable_key_vault ? azurerm_key_vault.main[0].vault_uri : null
}

# Database secret references (for use in applications)
output "postgres_username_secret_name" {
  description = "Name of the PostgreSQL username secret in Key Vault"
  value       = var.enable_key_vault ? azurerm_key_vault_secret.postgres_username[0].name : null
}

output "postgres_password_secret_name" {
  description = "Name of the PostgreSQL password secret in Key Vault"
  value       = var.enable_key_vault ? azurerm_key_vault_secret.postgres_password[0].name : null
}

output "postgres_database_secret_name" {
  description = "Name of the PostgreSQL database secret in Key Vault"
  value       = var.enable_key_vault ? azurerm_key_vault_secret.postgres_database[0].name : null
}

output "postgres_connection_string_secret_name" {
  description = "Name of the PostgreSQL connection string secret in Key Vault"
  value       = var.enable_key_vault ? azurerm_key_vault_secret.postgres_connection_string[0].name : null
}

output "cluster_identity_principal_id" {
  description = "Principal ID of the AKS cluster managed identity"
  value       = azurerm_kubernetes_cluster.main.identity[0].principal_id
}

# Additional outputs needed for Secret Provider Class
output "tenant_id" {
  description = "Azure tenant ID"
  value       = data.azurerm_client_config.current.tenant_id
}

output "kubelet_identity_client_id" {
  description = "Client ID of the AKS kubelet managed identity"
  value       = azurerm_kubernetes_cluster.main.kubelet_identity[0].client_id
}

output "kubelet_identity_object_id" {
  description = "Object ID of the AKS kubelet managed identity"
  value       = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}
