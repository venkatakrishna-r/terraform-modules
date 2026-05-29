# Azure Virtual Network Module

A reusable Terraform module for deploying Azure Virtual Networks (VNets) with optional encryption settings.

---

## Features

- Creates an Azure Virtual Network with one or more address spaces
- Optional VNet encryption with configurable enforcement mode
- Outputs `id`, `name`, and `resource_group_name` for downstream subnet and NSG modules

---

## Usage

```hcl
module "vnet" {
  source = "./modules/Azure/networking/virtual-network"

  name                = "vnet-prod"
  location            = "eastus"
  resource_group_name = "rg-networking-prod"
  address_space       = ["10.0.0.0/16"]
}
```

---

## Examples

### Minimal VNet

```hcl
module "vnet" {
  source = "./modules/Azure/networking/virtual-network"

  name                = "vnet-dev"
  location            = "eastus"
  resource_group_name = module.rg.name
  address_space       = ["10.1.0.0/16"]
}
```

### VNet with encryption enabled

```hcl
module "vnet_encrypted" {
  source = "./modules/Azure/networking/virtual-network"

  name                = "vnet-prod-secure"
  location            = "eastus"
  resource_group_name = module.rg.name
  address_space       = ["10.0.0.0/16"]

  encryption_enabled      = true
  encryption_enforcement  = "DropUnencrypted"  # Blocks unencrypted VM-to-VM traffic
}
```

### Multi-region VNets

```hcl
locals {
  regions = {
    primary   = { location = "eastus",  cidr = "10.0.0.0/16" }
    secondary = { location = "westus2", cidr = "10.1.0.0/16" }
  }
}

module "vnets" {
  for_each = local.regions

  source = "./modules/Azure/networking/virtual-network"

  name                = "vnet-${each.key}"
  location            = each.value.location
  resource_group_name = module.rg.name
  address_space       = [each.value.cidr]
}
```

### Full networking stack — VNet → Subnet → NSG

```hcl
module "rg" {
  source   = "./modules/Azure/resource-group"
  name     = "rg-networking-prod"
  location = "eastus"
}

module "vnet" {
  source              = "./modules/Azure/networking/virtual-network"
  name                = "vnet-prod"
  location            = module.rg.location
  resource_group_name = module.rg.name
  address_space       = ["10.0.0.0/16"]
}

module "subnet_app" {
  source               = "./modules/Azure/networking/subnet"
  name                 = "snet-app"
  resource_group_name  = module.rg.name
  virtual_network_name = module.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
```

---

## Inputs

| Name | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| `name` | `string` | — | yes | Name of the virtual network |
| `location` | `string` | — | yes | Azure region |
| `resource_group_name` | `string` | — | yes | Resource group to deploy into |
| `address_space` | `list(string)` | — | yes | One or more CIDR address spaces (e.g. `["10.0.0.0/16"]`) |
| `encryption_enabled` | `bool` | `false` | no | Enable VNet encryption for VM-to-VM traffic |
| `encryption_enforcement` | `string` | `"AllowUnencrypted"` | no | `AllowUnencrypted` or `DropUnencrypted` |

---

## Outputs

| Name | Description |
|------|-------------|
| `id` | Resource ID of the virtual network |
| `name` | Name of the virtual network |
| `resource_group_name` | Resource group the VNet belongs to |

---

## Notes

- **Address space planning**: Choose CIDRs that don't overlap with on-premises networks or peered VNets. Common ranges: `10.0.0.0/16` (65k IPs), `172.16.0.0/12`, `192.168.0.0/16`.
- **VNet encryption** (`DropUnencrypted`) requires that all VMs in the VNet use VM SKUs that support accelerated networking. Non-compliant VMs will lose connectivity.
- The VNet itself does not create subnets — use the `subnet` module for each subnet.
