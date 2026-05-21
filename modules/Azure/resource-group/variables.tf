variable "name" {
  description = "Name of the resource group."
  type        = string
}

variable "location" {
  description = "Location of the resource group."
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to the resource group."
  type        = map(string)
  default     = {}
}