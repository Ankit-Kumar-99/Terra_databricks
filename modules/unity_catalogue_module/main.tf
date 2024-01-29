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


variable "databricks_resource_id" {
  description = "The Azure resource ID for the databricks workspace deployment."
}

locals {
  resource_regex            = "(?i)subscriptions/(.+)/resourceGroups/(.+)/providers/Microsoft.Databricks/workspaces/(.+)"
  subscription_id           = regex(local.resource_regex, var.databricks_resource_id)[0]
  resource_group            = regex(local.resource_regex, var.databricks_resource_id)[1]
  databricks_workspace_name = regex(local.resource_regex, var.databricks_resource_id)[2]
  #tenant_id = data.azurerm_client_config.current.tenant_id
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



#provider for databrics workspace
provider "databricks" {
  host = local.databricks_workspace_host
}


#create a managed identity to be used by unity catalog metastore
resource "azurerm_databricks_access_connector" "ext_access_connector" {
  name                = "terra_metastore"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  identity {
    type = "SystemAssigned"
  }
}

#Create a storage account to be used by unity catalog metastore as root storage
resource "azurerm_storage_account" "ext_storage" {
  name                     = "${local.prefix}extstorage"
  resource_group_name      = data.azurerm_resource_group.this.name
  location                 = data.azurerm_resource_group.this.location
  tags                     = data.azurerm_resource_group.this.tags
  account_tier             = "Standard"
  account_replication_type = "GRS"
  is_hns_enabled           = true
}

#Create a container in storage account to be used by unity catalog metastore as root storage
resource "azurerm_storage_container" "ext_storage" {
  name                  = "${local.prefix}-ext"
  storage_account_name  = azurerm_storage_account.ext_storage.name
  container_access_type = "private"
}

#Assign the Storage Blob Data Contributor role to managed identity to allow unity catalog to access the storage
resource "azurerm_role_assignment" "mi_data_contributor" {
  scope                = azurerm_storage_account.ext_storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.ext_access_connector.identity[0].principal_id
}


#Create the first unity catalog metastore
resource "databricks_metastore" "this" {
  provider      = databricks.accounts
  name          = "primary"
  force_destroy = true
  region        = data.azurerm_resource_group.this.location
}

# Assign managed identity to metastore
resource "databricks_metastore_data_access" "first" {
  metastore_id = databricks_metastore.this.id
  name         = "the-metastore-key"
  azure_managed_identity {
    access_connector_id = azurerm_databricks_access_connector.ext_access_connector.id
  }
  is_default = true
}


# Attach the databricks workspace to the metastore
resource "databricks_metastore_assignment" "this" {
  provider             = databricks.accounts
  workspace_id         = 5382674463658831
  metastore_id         = databricks_metastore.this.id
  default_catalog_name = "hive_metastore"
}

# Initialize provider at Azure account level 
provider "databricks" {
  alias      = "accounts"
  host       = "https://accounts.azuredatabricks.net"
  account_id = "a637d602-ce36-472f-af49-6339e477966d"
}









