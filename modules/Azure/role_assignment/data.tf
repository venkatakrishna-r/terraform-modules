data "azurerm_role_definition" "selected" {
  count  = var.role_definition_id == null ? 1 : 0
  name   = var.role_definition_name
  scope  = var.scope
}