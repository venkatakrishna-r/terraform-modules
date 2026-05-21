output "vm_id" {
  description = "The ID of the Virtual Machine"
  value       = azurerm_windows_virtual_machine.vm.id
}

output "vm_name" {
  description = "The name of the Virtual Machine"
  value       = azurerm_windows_virtual_machine.vm.name
}

output "nic_id" {
  description = "The ID of the NIC"
  value       = azurerm_network_interface.nic.id
}

output "nic_private_ip" {
  description = "The private IP address of the NIC"
  value       = azurerm_network_interface.nic.ip_configuration[0].private_ip_address
}

output "vm_system_identity" {
  value = azurerm_windows_virtual_machine.vm.identity[0].principal_id  
}