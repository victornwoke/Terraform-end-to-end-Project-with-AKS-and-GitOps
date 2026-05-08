terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstate1778281586"
    container_name       = "tfstate"
    key                  = "dev/terraform.tfstate"
    use_azuread_auth     = false
    use_msi              = truec
  }
}
