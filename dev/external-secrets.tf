# =====================================================
# External Secrets Operator Configuration
# =====================================================
# This file manages the complete External Secrets Operator lifecycle:
# 1. Installs External Secrets Operator via Helm
# 2. Creates SecretStore for Azure Key Vault integration  
# 3. Creates ExternalSecret to sync secrets from Key Vault
# 4. Uses null_resource approach to avoid chicken-egg problems
# =====================================================

# Install External Secrets Operator and configure Azure Key Vault integration
resource "null_resource" "external_secrets_operator" {
  count = var.enable_key_vault ? 1 : 0

  triggers = {
    cluster_id    = azurerm_kubernetes_cluster.main.id
    key_vault_id  = azurerm_key_vault.main[0].id
    kubelet_id    = azurerm_kubernetes_cluster.main.kubelet_identity[0].client_id
    environment   = var.environment
    secrets_ready = "${azurerm_key_vault_secret.postgres_username[0].id}-${azurerm_key_vault_secret.postgres_password[0].id}-${azurerm_key_vault_secret.postgres_database[0].id}-${azurerm_key_vault_secret.postgres_connection_string[0].id}"
  }

  provisioner "local-exec" {
    command = <<-EOT
      ${path.module}/scripts/install-external-secrets.sh \
        "${azurerm_resource_group.main.name}" \
        "${azurerm_kubernetes_cluster.main.name}" \
        "${azurerm_key_vault.main[0].vault_uri}" \
        "${azurerm_kubernetes_cluster.main.kubelet_identity[0].client_id}" \
        "${var.environment}" \
        "${azurerm_key_vault_secret.postgres_username[0].name}" \
        "${azurerm_key_vault_secret.postgres_password[0].name}" \
        "${azurerm_key_vault_secret.postgres_database[0].name}" \
        "${azurerm_key_vault_secret.postgres_connection_string[0].name}"
    EOT
  }

  # Note: No destroy provisioner needed since destroying the AKS cluster
  # automatically removes all Kubernetes resources including External Secrets Operator

  depends_on = [
    azurerm_kubernetes_cluster.main,
    azurerm_key_vault.main,
    azurerm_key_vault_secret.postgres_username,
    azurerm_key_vault_secret.postgres_password,
    azurerm_key_vault_secret.postgres_database,
    azurerm_key_vault_secret.postgres_connection_string,
    time_sleep.wait_for_cluster,
    azurerm_role_assignment.aks_admin
  ]
}
