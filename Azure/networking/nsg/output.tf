output "id" {
  description = "The ID of the Network Security Group."
  value       = azurerm_network_security_group.this.id
}

output "subnet_associations" {
  description = "List of subnet IDs associated with the NSG."
  value       = keys(azurerm_subnet_network_security_group_association.nsg_association)
}