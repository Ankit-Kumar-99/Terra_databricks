variable "databricks_resource_id" {
  description = "The Azure resource ID for the databricks workspace deployment."
}

locals {
  resource_regex            = "(?i)subscriptions/(.+)/resourceGroups/(.+)/providers/Microsoft.Databricks/workspaces/(.+)"
  subscription_id           = regex(local.resource_regex, var.databricks_resource_id)[0]
  resource_group            = regex(local.resource_regex, var.databricks_resource_id)[1]
  databricks_workspace_name = regex(local.resource_regex, var.databricks_resource_id)[2]
  tenant_id = data.azurerm_client_config.current.tenant_id
  databricks_workspace_host = data.azurerm_databricks_workspace.this.workspace_url
  databricks_workspace_id   = data.azurerm_databricks_workspace.this.workspace_id
  prefix                    = replace(replace(lower(data.azurerm_resource_group.this.name), "rg", ""), "-", "")
}

data "azurerm_resource_group" "this" {
  name = local.resource_group
}

data "azurerm_client_config" "current" {
}

data "azurerm_databricks_workspace" "this" {
  name                = local.databricks_workspace_name
  resource_group_name = local.resource_group
}


terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    databricks = {
      source = "databricks/databricks"
    }
  }
}

provider "azurerm" {
  subscription_id = local.subscription_id
  features {}
}

provider "databricks" {
  host = local.databricks_workspace_host
}

provider "databricks" {
  alias      = "accounts"
  host       = "https://accounts.azuredatabricks.net"
  account_id = "a637d602-ce36-472f-af49-6339e477966d"
}


resource "databricks_metastore" "this" {
  provider      = databricks.accounts
  name          = "primary"
  force_destroy = true
  region        = data.azurerm_resource_group.this.location
}

resource "databricks_metastore_assignment" "this" {
  provider             = databricks.accounts
  workspace_id         = 5382674463658831
  metastore_id         = databricks_metastore.this.id
  default_catalog_name = "hive_metastore"
}

resource "azurerm_databricks_access_connector" "ext_access_connector" {
  name                = "ext-databricks-mi"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_storage_account" "ext_storage" {
  name                     = "${local.prefix}extstorage"
  resource_group_name      = data.azurerm_resource_group.this.name
  location                 = data.azurerm_resource_group.this.location
  tags                     = data.azurerm_resource_group.this.tags
  account_tier             = "Standard"
  account_replication_type = "GRS"
  is_hns_enabled           = true
}

resource "azurerm_storage_container" "ext_storage" {
  name                  = "${local.prefix}-ext"
  storage_account_name  = azurerm_storage_account.ext_storage.name
  container_access_type = "private"
}

resource "azurerm_role_assignment" "ext_storage" {
  scope                = azurerm_storage_account.ext_storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.ext_access_connector.identity[0].principal_id
}
