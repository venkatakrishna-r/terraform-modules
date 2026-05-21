variable "nsg_name" {
  description = "Name of the Network Security Group for APIM."
  type        = string
}

variable "location" {
  description = "Location of the NSG."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "security_rules" {
  description = "Security rules for the NSG."
  type = map(object({
    priority                  = number
    direction                 = string
    access                    = string
    protocol                  = string
    source_port_range         = optional(string)
    source_port_ranges        = optional(list(string))
    destination_port_range    = optional(string)
    destination_port_ranges   = optional(list(string))
    source_address_prefix     = optional(string)
    source_address_prefixes   = optional(list(string))
    destination_address_prefix = optional(string)
    destination_address_prefixes = optional(list(string))
  }))
}


variable "subnet_ids" {
  description = "Map of subnet name to IDs to associate with the NSG."
  type        = map(string)
}