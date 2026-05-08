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

output "argocd_server_ip" {
  description = "ArgoCD server external IP"
  value       = "Run 'kubectl get svc argocd-server -n argocd' to get the external IP"
}

# Commented out since Log Analytics workspace is optional
# output "log_analytics_workspace_id" {
#   description = "Log Analytics workspace ID"
#   value       = azurerm_log_analytics_workspace.main.id
# }

output "argocd_admin_password" {
  description = "ArgoCD admin password command"
  value       = "Run 'kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d' to get the admin password"
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}
