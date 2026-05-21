# modules/subnet/variables.tf
variable "name" {
  description = "The name of the subnet."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
}

variable "virtual_network_name" {
  description = "The name of the virtual network."
  type        = string
}

variable "address_prefixes" {
  description = "The address prefixes for the subnet."
  type        = list(string)
}

variable "service_endpoints" {
  description = "List of service endpoints to enable on the subnet."
  type        = list(string)
  default     = []
}

variable "delegations" {
  description = "A list of delegations for the subnet."
  type = list(object({
    name         = string
    service_name = string
    actions      = list(string)
  }))
  default = []
}