# Azure Subnet Module

A reusable Terraform module for creating Azure subnets within an existing Virtual Network, with support for service endpoints and service delegations.

---

## Features

- Creates a subnet within an existing VNet
- Optional service endpoints (e.g. `Microsoft.Storage`, `Microsoft.KeyVault`, `Microsoft.Sql`)
- Optional service delegations for PaaS services (e.g. App Service, ACI, Azure NetApp Files)
- Multiple delegations supported per subnet

---

## Usage

```hcl
module "subnet_app" {
  source = "./modules/Azure/networking/subnet"

  name                 = "snet-app"
  resource_group_name  = "rg-networking-prod"
  virtual_network_name = "vnet-prod"
  address_prefixes     = ["10.0.1.0/24"]
}
```

---

## Examples

### Simple subnet — no endpoints or delegations

```hcl
module "subnet_app" {
  source = "./modules/Azure/networking/subnet"

  name                 = "snet-app"
  resource_group_name  = module.rg.name
  virtual_network_name = module.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
```

### Subnet with service endpoints (for Storage and Key Vault)

```hcl
module "subnet_data" {
  source = "./modules/Azure/networking/subnet"

  name                 = "snet-data"
  resource_group_name  = module.rg.name
  virtual_network_name = module.vnet.name
  address_prefixes     = ["10.0.2.0/24"]

  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.Sql"
  ]
}
```

### Subnet with delegation (App Service VNet Integration)

```hcl
module "subnet_appservice" {
  source = "./modules/Azure/networking/subnet"

  name                 = "snet-appservice"
  resource_group_name  = module.rg.name
  virtual_network_name = module.vnet.name
  address_prefixes     = ["10.0.3.0/24"]

  delegations = [
    {
      name         = "app-service-delegation"
      service_name = "Microsoft.Web/serverFarms"
      actions      = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  ]
}
```

### Subnet with delegation (Azure Container Instances)

```hcl
module "subnet_aci" {
  source = "./modules/Azure/networking/subnet"

  name                 = "snet-aci"
  resource_group_name  = module.rg.name
  virtual_network_name = module.vnet.name
  address_prefixes     = ["10.0.4.0/24"]

  delegations = [
    {
      name         = "aci-delegation"
      service_name = "Microsoft.ContainerInstance/containerGroups"
      actions      = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  ]
}
```

### Multiple subnets from the same root module

```hcl
locals {
  subnets = {
    app  = { prefix = "10.0.1.0/24", endpoints = [] }
    data = { prefix = "10.0.2.0/24", endpoints = ["Microsoft.Storage", "Microsoft.Sql"] }
    mgmt = { prefix = "10.0.3.0/24", endpoints = [] }
  }
}

module "subnets" {
  for_each = local.subnets

  source = "./modules/Azure/networking/subnet"

  name                 = "snet-${each.key}"
  resource_group_name  = module.rg.name
  virtual_network_name = module.vnet.name
  address_prefixes     = [each.value.prefix]
  service_endpoints    = each.value.endpoints
}
```

---

## Inputs

| Name | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| `name` | `string` | — | yes | Name of the subnet |
| `resource_group_name` | `string` | — | yes | Resource group of the parent VNet |
| `virtual_network_name` | `string` | — | yes | Name of the parent virtual network |
| `address_prefixes` | `list(string)` | — | yes | CIDR address prefix(es) for the subnet |
| `service_endpoints` | `list(string)` | `[]` | no | Service endpoints to enable (e.g. `Microsoft.Storage`) |
| `delegations` | `list(object)` | `[]` | no | Service delegations for PaaS services (see below) |

### `delegations` object (per entry)

| Field | Type | Description |
|-------|------|-------------|
| `name` | `string` | Delegation block name (arbitrary, must be unique per subnet) |
| `service_name` | `string` | Azure service to delegate to (e.g. `Microsoft.Web/serverFarms`) |
| `actions` | `list(string)` | Actions the service is permitted to perform on the subnet |

---

## Outputs

| Name | Description |
|------|-------------|
| `id` | Resource ID of the subnet |
| `name` | Name of the subnet |

---

## Notes

- **Service endpoints vs. Private Endpoints**: Service endpoints route traffic over the Azure backbone but the storage/service still has a public IP. For fully private access, use Azure Private Endpoints instead.
- **Delegation**: A delegated subnet can only be used by the delegated service. Do not place other resources (VMs, etc.) in a delegated subnet.
- **Address planning**: Azure reserves the first 4 IPs and the last IP in every subnet. A `/24` gives 251 usable IPs.
- Common service endpoint values: `Microsoft.Storage`, `Microsoft.KeyVault`, `Microsoft.Sql`, `Microsoft.ServiceBus`, `Microsoft.EventHub`, `Microsoft.ContainerRegistry`.
