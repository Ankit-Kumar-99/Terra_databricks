# main.tf


module "databricks" {
  subscription_id = var.subscription_id
  client_secret = var.client_secret
  tenant_id = var.tenant_id
  client_id = var.client_id
  source = "./modules/databricks_module"
  prefix                              = var.prefix
  location                            = var.location
  spark_version                       = var.spark_version
  node_type_id                        = var.node_type_id
  account_id                          = var.account_id
  azure_client_id                     = var.azure_client_id
  databricks_host                     = var.databricks_host
  databricks_resource_id              = var.databricks_resource_id
  databricks_service_principal_display_name = var.databricks_service_principal_display_name
}

module "unity_catalogue" {
  source = "./modules/unity_catalogue_module"

  databricks_resource_id = var.databricks_resource_id
}

