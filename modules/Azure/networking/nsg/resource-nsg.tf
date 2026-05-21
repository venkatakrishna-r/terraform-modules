resource "azurerm_network_security_group" "this" {
  name                = var.nsg_name
  location            = var.location
  resource_group_name = var.resource_group_name
}

# Add security rules dynamically
resource "azurerm_network_security_rule" "rules" {
  for_each = var.security_rules

  name                        = each.key
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = lookup(each.value, "source_port_range", null)
  source_port_ranges          = lookup(each.value, "source_port_ranges", ["*"])  # Ensure a default value
  destination_port_range      = lookup(each.value, "destination_port_range", null)
  destination_port_ranges     = lookup(each.value, "destination_port_ranges", [])
  source_address_prefix       = lookup(each.value, "source_address_prefix", null)
  source_address_prefixes     = lookup(each.value, "source_address_prefixes", [])
  destination_address_prefix  = lookup(each.value, "destination_address_prefix", null)
  destination_address_prefixes = lookup(each.value, "destination_address_prefixes", [])

  network_security_group_name = azurerm_network_security_group.this.name
  resource_group_name         = var.resource_group_name
}



# Associate NSG with VNet Subnets
resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  for_each = var.subnet_ids

  subnet_id                 = each.value
  network_security_group_id = azurerm_network_security_group.this.id
}