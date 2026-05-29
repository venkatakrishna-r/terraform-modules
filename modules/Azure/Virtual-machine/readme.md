# Azure Windows Virtual Machine Module

A reusable Terraform module for deploying **Windows Virtual Machines** on Azure, with support for managed data disks, local user creation, auto-shutdown, boot diagnostics, and system-assigned managed identity.

---

## Features

- Windows VM with system-assigned managed identity
- Static or dynamic private IP via a dedicated NIC
- Configurable OS disk (type, size, caching)
- Multiple managed data disks (map-based, auto-attached)
- Local Windows user creation via PowerShell custom data
- Auto-shutdown schedule (Azure Dev/Test Labs)
- Boot diagnostics via storage account
- Patch management and secure boot configuration
- Availability zone support

---

## Usage

```hcl
module "windows_vm" {
  source = "./modules/Azure/Virtual-machine"

  vm_name             = "prod-app-vm-01"
  location            = "eastus"
  resource_group_name = "rg-prod-app"
  subnet_id           = "/subscriptions/.../subnets/snet-app"
  private_ip_address  = "10.0.1.10"

  vm_size        = "Standard_D4s_v3"
  admin_username = "azureadmin"
  admin_password = var.vm_admin_password   # Pass via tfvars or Key Vault reference

  os_disk = {
    name                 = "prod-app-vm-01-osdisk"
    storage_account_type = "Premium_LRS"
    caching              = "ReadWrite"
    size_gb              = 128
  }

  image = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  tags = {
    environment = "production"
    team        = "platform"
  }
}
```

---

## Examples

### Minimal — defaults only

```hcl
module "vm_minimal" {
  source = "./modules/Azure/Virtual-machine"

  vm_name             = "dev-vm-01"
  location            = "eastus"
  resource_group_name = "rg-dev"
  subnet_id           = module.networking.subnet_id
  private_ip_address  = "10.0.2.20"
  admin_username      = "azureadmin"
  admin_password      = var.vm_admin_password

  os_disk = {
    name                 = "dev-vm-01-osdisk"
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
    size_gb              = 64
  }

  image = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}
```

### With data disks

```hcl
module "vm_with_disks" {
  source = "./modules/Azure/Virtual-machine"

  vm_name             = "sql-vm-01"
  location            = "eastus"
  resource_group_name = "rg-data"
  subnet_id           = module.networking.subnet_id
  private_ip_address  = "10.0.1.30"
  admin_username      = "azureadmin"
  admin_password      = var.vm_admin_password

  vm_size = "Standard_E8s_v3"

  os_disk = {
    name                 = "sql-vm-01-osdisk"
    storage_account_type = "Premium_LRS"
    caching              = "ReadWrite"
    size_gb              = 128
  }

  image = {
    publisher = "MicrosoftSQLServer"
    offer     = "sql2022-ws2022"
    sku       = "enterprise"
    version   = "latest"
  }

  data_disks = {
    data = {
      name                 = "sql-vm-01-data"
      storage_account_type = "Premium_LRS"
      disk_size_gb         = 512
      lun                  = 0
      caching              = "ReadOnly"
    }
    logs = {
      name                 = "sql-vm-01-logs"
      storage_account_type = "Premium_LRS"
      disk_size_gb         = 256
      lun                  = 1
      caching              = "None"
    }
  }
}
```

### With local users and auto-shutdown

```hcl
module "vm_with_users" {
  source = "./modules/Azure/Virtual-machine"

  vm_name             = "dev-jumpbox-01"
  location            = "westus2"
  resource_group_name = "rg-jumpbox"
  subnet_id           = module.networking.subnet_id
  private_ip_address  = "10.0.3.10"
  admin_username      = "azureadmin"
  admin_password      = var.vm_admin_password

  os_disk = {
    name                 = "dev-jumpbox-01-osdisk"
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
    size_gb              = 64
  }

  image = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }

  # Create local Windows users on first boot
  users = [
    {
      name     = "devuser"
      password = var.devuser_password
      groups   = ["Administrators"]
    },
    {
      name     = "appservice"
      password = var.appservice_password
      groups   = ["Users", "Remote Desktop Users"]
    }
  ]

  # Shut down daily at 7 PM UTC
  auto_shutdown_time = "1900"

  tags = {
    environment = "dev"
    auto_shutdown = "true"
  }
}
```

### With boot diagnostics and availability zone

```hcl
module "vm_with_diagnostics" {
  source = "./modules/Azure/Virtual-machine"

  vm_name             = "prod-vm-01"
  location            = "eastus"
  resource_group_name = "rg-prod"
  subnet_id           = module.networking.subnet_id
  private_ip_address  = "10.0.1.50"
  admin_username      = "azureadmin"
  admin_password      = var.vm_admin_password

  vm_size            = "Standard_D4s_v3"
  availability_zone  = "1"
  diagnostics_sa_id  = module.storage_account.primary_blob_endpoint

  os_disk = {
    name                 = "prod-vm-01-osdisk"
    storage_account_type = "Premium_LRS"
    caching              = "ReadWrite"
    size_gb              = 128
  }

  image = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}
```

---

## Inputs

| Name | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| `vm_name` | `string` | — | yes | Name of the virtual machine |
| `location` | `string` | — | yes | Azure region |
| `resource_group_name` | `string` | — | yes | Resource group name |
| `subnet_id` | `string` | — | yes | Subnet ID for the NIC |
| `private_ip_address` | `string` | — | yes | Static private IP address |
| `admin_username` | `string` | — | yes | Local administrator username |
| `admin_password` | `string` | — | yes | Local administrator password |
| `os_disk` | `object` | — | yes | OS disk configuration (see below) |
| `image` | `object` | — | yes | Source image reference (see below) |
| `vm_size` | `string` | `"Standard_D2s_v3"` | no | VM SKU size |
| `availability_zone` | `string` | `null` | no | Availability zone (`"1"`, `"2"`, or `"3"`) |
| `private_ip_address_allocation` | `string` | `"Static"` | no | `Static` or `Dynamic` |
| `tags` | `map(string)` | `{}` | no | Resource tags |
| `data_disks` | `map(object)` | `{}` | no | Managed data disks to attach (see below) |
| `users` | `list(object)` | `[]` | no | Local Windows users to create on first boot |
| `auto_shutdown_time` | `string` | `null` | no | Daily auto-shutdown in HHmm UTC (e.g. `"1900"`) |
| `diagnostics_sa_id` | `string` | `null` | no | Storage account blob endpoint for boot diagnostics |
| `bypass_platform_safety_checks_on_user_schedule_enabled` | `bool` | `true` | no | Bypass platform safety checks for user-scheduled patching |
| `patch_assessment_mode` | `string` | `"AutomaticByPlatform"` | no | Patch assessment mode |
| `patch_mode` | `string` | `"AutomaticByPlatform"` | no | Patch management mode |
| `secure_boot_enabled` | `bool` | `false` | no | Enable Trusted Launch secure boot |

### `os_disk` object

| Field | Type | Description |
|-------|------|-------------|
| `name` | `string` | OS disk resource name |
| `storage_account_type` | `string` | e.g. `Premium_LRS`, `Standard_LRS` |
| `caching` | `string` | `ReadWrite`, `ReadOnly`, or `None` |
| `size_gb` | `number` | Disk size in GB |

### `image` object

| Field | Type | Description |
|-------|------|-------------|
| `publisher` | `string` | e.g. `MicrosoftWindowsServer` |
| `offer` | `string` | e.g. `WindowsServer` |
| `sku` | `string` | e.g. `2022-Datacenter` |
| `version` | `string` | e.g. `latest` |

### `data_disks` map object (per entry)

| Field | Type | Description |
|-------|------|-------------|
| `name` | `string` | Managed disk resource name |
| `storage_account_type` | `string` | e.g. `Premium_LRS` |
| `disk_size_gb` | `number` | Disk size in GB |
| `lun` | `number` | Logical unit number (0–63, unique per VM) |
| `caching` | `string` | `ReadWrite`, `ReadOnly`, or `None` |

### `users` list object (per entry)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | `string` | — | Windows local username |
| `password` | `string` | — | User password |
| `groups` | `list(string)` | `["Administrators"]` | Local groups to add the user to |

---

## Outputs

| Name | Description |
|------|-------------|
| `vm_id` | Resource ID of the virtual machine |
| `vm_name` | Name of the virtual machine |
| `nic_id` | Resource ID of the network interface |
| `nic_private_ip` | Private IP address assigned to the NIC |
| `vm_system_identity` | Principal ID of the system-assigned managed identity |

---

## Notes

- **Passwords**: Avoid hardcoding passwords in `.tfvars`. Use Azure Key Vault references, environment variables (`TF_VAR_vm_admin_password`), or a secrets manager.
- **User creation**: The `users` variable injects a PowerShell script via `custom_data` (base64-encoded). This only runs on first boot — it is not idempotent.
- **Data disks**: LUN values must be unique per VM (0–63). Using a map key ensures stable ordering across plan/apply cycles.
- **Managed identity**: A system-assigned identity is always enabled. Use `vm_system_identity` output to grant the VM RBAC roles (e.g. Key Vault access).
- **Auto-shutdown**: Uses Azure Dev/Test Labs global schedule. Requires the `Microsoft.DevTestLab` resource provider to be registered in your subscription.
