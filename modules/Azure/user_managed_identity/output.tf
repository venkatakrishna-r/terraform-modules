# Output the ID of the created identity
output "identity_id" {
  value = azurerm_user_assigned_identity.identity.id
}

# Output the principal ID of the created identity (if needed)
output "identity_principal_id" {
  value = azurerm_user_assigned_identity.identity.principal_id
}
output "identity_client_id" {
  value = azurerm_user_assigned_identity.identity.client_id
}
