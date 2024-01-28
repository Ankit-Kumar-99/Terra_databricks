terraform {
  backend "azurerm" {
    storage_account_name = "uidemostorage"
    container_name       = "democontainer"
    key                  = "state.tfstate"
    resource_group_name  = "UI_resource"
  }
}