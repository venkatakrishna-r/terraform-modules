resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = var.private_ip_address_allocation
    private_ip_address            = var.private_ip_address
  }

  tags = var.tags
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                = var.vm_name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  identity {
    type = "SystemAssigned"
  } 
  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]
  bypass_platform_safety_checks_on_user_schedule_enabled = var.bypass_platform_safety_checks_on_user_schedule_enabled 
  patch_assessment_mode                                  = var.patch_assessment_mode                                  
  patch_mode                                             = var.patch_mode
  secure_boot_enabled                                    = var.secure_boot_enabled 

  zone = var.availability_zone

  os_disk {
    name                 = "${var.vm_name}-osdisk"
    caching              = var.os_disk.caching
    storage_account_type = var.os_disk.storage_account_type
    disk_size_gb         = var.os_disk.size_gb
  }
  source_image_reference {
    publisher = var.image.publisher
    offer     = var.image.offer
    sku       = var.image.sku
    version   = var.image.version
  }

  dynamic "boot_diagnostics" {
    for_each = var.diagnostics_sa_id != null ? [1] : []
    content {
      storage_account_uri = var.diagnostics_sa_id
    }
  }
  custom_data = local.user_creation_script != null ? base64encode(local.user_creation_script) : null
  tags = var.tags
}
/*
# 🔽 Attach multiple managed data disks
resource "azurerm_managed_disk" "datadisks" {
  for_each            = { for d in var.data_disks : d.name => d }
  name                = each.value.name
  location            = var.location
  resource_group_name = var.resource_group_name
  storage_account_type = each.value.storage_account_type
  create_option       = "Empty"
  disk_size_gb        = each.value.disk_size_gb
  tags                = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "disk_attach" {
  for_each           = azurerm_managed_disk.datadisks
  managed_disk_id    = each.value.id
  virtual_machine_id = azurerm_windows_virtual_machine.vm.id
  lun                = var.data_disks[lookup(keys(azurerm_managed_disk.datadisks), each.key)].lun
  caching            = var.data_disks[lookup(keys(azurerm_managed_disk.datadisks), each.key)].caching
}
*/
resource "azurerm_managed_disk" "datadisks" {
  for_each             = var.data_disks
  name                 = each.value.name
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = each.value.storage_account_type
  create_option        = "Empty"
  disk_size_gb         = each.value.disk_size_gb
  tags                 = var.tags
}


resource "azurerm_virtual_machine_data_disk_attachment" "disk_attach" {
  for_each           = var.data_disks
  managed_disk_id    = azurerm_managed_disk.datadisks[each.key].id
  virtual_machine_id = azurerm_windows_virtual_machine.vm.id
  lun                = each.value.lun
  caching            = each.value.caching
}


# 🔽 Auto-shutdown (optional)
resource "azurerm_dev_test_global_vm_shutdown_schedule" "shutdown" {
  count              = var.auto_shutdown_time != null ? 1 : 0
  virtual_machine_id = azurerm_windows_virtual_machine.vm.id
  location           = var.location
  enabled            = true
  daily_recurrence_time = var.auto_shutdown_time
  timezone           = "UTC"
  notification_settings {
    enabled = false
  }
}