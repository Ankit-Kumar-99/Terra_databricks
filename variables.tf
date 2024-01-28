# variables.tf
variable "subscription_id"{

}

variable "client_id"{

}

variable "tenant_id" {
  
}

variable "client_secret" {
  
}
variable "prefix" {
  type    = string
}

variable "location" {
  type    = string
}

variable "spark_version" {
  type    = string
}

variable "node_type_id" {
  type    = string
}

variable "account_id" {
  type    = string
}

variable "azure_client_id" {
  type    = string
}

variable "databricks_host" {
  type    = string
}

variable "databricks_resource_id" {
  type    = string
}

variable "databricks_service_principal_display_name" {
  type    = string
}

