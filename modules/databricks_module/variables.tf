#databricks_module/variables.tf

variable "subscription_id"{

}

variable "client_id"{

}

variable "tenant_id" {
  
}

variable "client_secret" {
  
}

variable "prefix" {
}

variable "location" {
}

variable "spark_version" {
}

variable "node_type_id" {
}

variable "account_id" {
}

variable "azure_client_id" {
}

variable "databricks_host" {
}

variable "databricks_resource_id" {
}

variable "databricks_service_principal_display_name" {
}

variable "display_name" {
    default =  "admins" 
}

variable "terrastorageaccuc_name" {
    default = "terrastorageaccuc" 
}

variable "terracontainer_name" {
    default = "terracontainer" 
}

variable "container_access_type" {
    default = "private" 
}
