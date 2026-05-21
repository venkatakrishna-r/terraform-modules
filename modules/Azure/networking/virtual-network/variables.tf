variable "name" {
  description = "The name of the virtual network."
  type        = string
}

variable "location" {
  description = "The Azure region for the virtual network."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
}

variable "address_space" {
  description = "The address space for the virtual network."
  type        = list(string)
}

variable "encryption_enabled" {
  description = "Whether encryption is enabled for the virtual network."
  type        = bool
  default     = false
}

variable "encryption_enforcement" {
  description = "Encryption enforcement for the virtual network."
  type        = string
  default     = "AllowUnencrypted"
}