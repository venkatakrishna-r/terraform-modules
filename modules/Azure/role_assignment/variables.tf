variable "scope" {
  description = "The scope at which the role assignment applies."
  type        = string
}

variable "role_definition_id" {
  description = "The ID of the role definition."
  type        = string
  default     = null
}

variable "role_definition_name" {
  description = "The name of the role definition (e.g., 'Reader', 'Contributor')."
  type        = string
  default     = null
}

variable "principal_id" {
  description = "The ID of the principal (user, group, or service principal)."
  type        = string
}
