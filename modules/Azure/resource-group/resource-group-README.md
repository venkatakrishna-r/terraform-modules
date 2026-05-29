# Azure Resource Group Module

A minimal, reusable Terraform module for creating Azure Resource Groups with consistent tagging.

---

## Features

- Creates an Azure Resource Group in any supported region
- Supports arbitrary tag maps for governance and cost management
- Outputs `id`, `name`, and `location` for use by dependent modules

---

## Usage

```hcl
module "resource_group" {
  source = "./modules/Azure/resource-group"

  name     = "rg-myapp-prod"
  location = "eastus"

  tags = {
    environment = "production"
    team        = "platform"
    managed_by  = "terraform"
  }
}
```

---

## Examples

### Minimal — no tags

```hcl
module "rg_minimal" {
  source = "./modules/Azure/resource-group"

  name     = "rg-dev-scratch"
  location = "westus2"
}
```

### Multiple resource groups (one per environment)

```hcl
locals {
  environments = {
    dev  = { location = "eastus",  tags = { environment = "dev" } }
    prod = { location = "eastus2", tags = { environment = "production" } }
  }
}

module "resource_groups" {
  for_each = local.environments

  source = "./modules/Azure/resource-group"

  name     = "rg-myapp-${each.key}"
  location = each.value.location
  tags     = each.value.tags
}

# Reference a specific RG output downstream
output "prod_rg_id" {
  value = module.resource_groups["prod"].id
}
```

### Chaining into a VNet module

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
```

---

## Inputs

| Name | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| `name` | `string` | — | yes | Name of the resource group |
| `location` | `string` | — | yes | Azure region (e.g. `eastus`, `westeurope`) |
| `tags` | `map(string)` | `{}` | no | Tags to apply to the resource group |

---

## Outputs

| Name | Description |
|------|-------------|
| `id` | Resource ID of the resource group |
| `name` | Name of the resource group |
| `location` | Azure region of the resource group |

---

## Notes

- Resource group names must be globally unique within a subscription and can be up to 90 characters.
- Deleting a resource group **deletes all resources inside it**. Use `prevent_destroy = true` in production:

```hcl
module "rg" {
  source   = "./modules/Azure/resource-group"
  name     = "rg-prod-critical"
  location = "eastus"
}

# Add lifecycle protection in the calling root module
resource "azurerm_resource_group" "protected" {
  name     = module.rg.name
  location = module.rg.location
  lifecycle {
    prevent_destroy = true
  }
}
```
