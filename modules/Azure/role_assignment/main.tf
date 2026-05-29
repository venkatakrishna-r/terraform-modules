resource "azurerm_role_assignment" "this" {
  scope              = var.scope
  role_definition_id = var.role_definition_id != null ? var.role_definition_id : data.azurerm_role_definition.selected[0].id
  principal_id       = var.principal_id
}
