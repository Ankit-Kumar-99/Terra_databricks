#databricks_module/main.tf

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.86.0"
      
    }
    databricks = {
      source  = "databrickslabs/databricks"
      version = "0.3.1"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  client_secret = var.client_secret
  tenant_id = var.tenant_id
  client_id = var.client_id
 features {}
}
  
provider "databricks" {
 azure_workspace_resource_id = var.account_id
 host = var.databricks_host
}

resource "azurerm_resource_group" "new_rg" {
 name   = "${var.prefix}-new-rg"
 location = var.location
}

resource "azurerm_databricks_workspace" "myworkspace" {
 location      = azurerm_resource_group.new_rg.location
 name        = "${var.prefix}-workspace"
 resource_group_name = azurerm_resource_group.new_rg.name
 sku         = "premium"


}

resource "databricks_cluster" "simple_cluster" {
  cluster_name            = "${var.prefix}-Simple-Cluster"
  spark_version           = var.spark_version
  node_type_id            = var.node_type_id
  num_workers             = 2
  autotermination_minutes = 90
}

resource "azuread_application" "databricks_app" {
  display_name = var.databricks_service_principal_display_name
}

data "databricks_group" "admins" {
  display_name = var.display_name
}

resource "databricks_service_principal" "sp" {
  application_id = var.azure_client_id
  display_name   = var.databricks_service_principal_display_name
}

resource "databricks_group_member" "i-am-admin" {
  group_id  = data.databricks_group.admins.id
  member_id = databricks_service_principal.sp.id
}

