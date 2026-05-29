variable "storage_account_name" {
  description = "The name of the Azure Storage Account"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group where the storage account is created"
  type        = string
}

variable "location" {
  description = "The Azure location where the storage account will be created"
  type        = string
}

variable "account_tier" {
  description = "Storage Account tier"
  type        = string
  default     = "Standard"
}

variable "replication_type" {
  description = "Replication type for the storage account"
  type        = string
  default     = "LRS"
}

variable "storage_container_names" {
  type    = list(string)
  default = ["default-container"]  # Set your default containers here
  description = "List of storage container names to create"
}

#variable "user_assigned_identity_id" {
#  type        = string
#  description = "User Assigned Managed Identity ID"
#  default     = null
#}

variable "allowed_subnet_ids" {   # For service endpoint connection
  description = "List of subnet IDs allowed to access the storage account"  
  type        = list(string)
  default     = []
}
 
variable "allowed_subnet_depends_on" {    # For service endpoint connection
  description = "List of resources the storage account should depend on (typically a subnet data or resource block)."
  type        = list(any)
  default     = []
}

#variable "private_link_subnet_id" {
#  description = "Subnet ID for Private Link"
#  type        = string
#}

#variable "private_dns_zone_ids" {
#  description = "List of Private DNS Zone IDs"
#  type        = list(string)
#}

variable "adls_storage_account_id" {
  description = "Storage Account ID for ADLS diagnostic logs destination"
  type        = string
  default     = null
}

variable "enable_adls_diagnostics" {
  description = "Enable diagnostic settings to send logs to ADLS"
  type        = bool
  default     = false
}