# Azure Network Security Group (NSG) Module

A reusable Terraform module for creating Azure Network Security Groups with dynamic security rules and automatic subnet associations.

---

## Features

- Creates an NSG with any number of inbound/outbound security rules (map-driven)
- Each rule supports single or ranged port/address specifications
- Automatically associates the NSG with one or more subnets
- Outputs the NSG ID and the list of associated subnet names

---

## Usage

```hcl
module "nsg_app" {
  source = "./modules/Azure/networking/nsg"

  nsg_name            = "nsg-app"
  location            = "eastus"
  resource_group_name = "rg-networking-prod"

  security_rules = {
    allow_https_inbound = {
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }

  subnet_ids = {
    app = module.subnet_app.id
  }
}
```

---

## Examples

### Web-tier NSG — allow HTTPS inbound, deny all else

```hcl
module "nsg_web" {
  source = "./modules/Azure/networking/nsg"

  nsg_name            = "nsg-web"
  location            = module.rg.location
  resource_group_name = module.rg.name

  security_rules = {
    allow_https_inbound = {
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
    allow_http_inbound = {
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }

  subnet_ids = {
    web = module.subnet_web.id
  }
}
```

### App-tier NSG — restrict to specific source subnet

```hcl
module "nsg_app" {
  source = "./modules/Azure/networking/nsg"

  nsg_name            = "nsg-app"
  location            = module.rg.location
  resource_group_name = module.rg.name

  security_rules = {
    allow_from_web_tier = {
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_ranges    = ["8080", "8443"]
      source_address_prefix      = "10.0.1.0/24"   # web subnet CIDR
      destination_address_prefix = "*"
    }
    allow_rdp_from_bastion = {
      priority                   = 200
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3389"
      source_address_prefix      = "10.0.10.0/27"  # bastion subnet
      destination_address_prefix = "*"
    }
    deny_all_inbound = {
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }

  subnet_ids = {
    app = module.subnet_app.id
  }
}
```

### Data-tier NSG — allow SQL from app tier only

```hcl
module "nsg_data" {
  source = "./modules/Azure/networking/nsg"

  nsg_name            = "nsg-data"
  location            = module.rg.location
  resource_group_name = module.rg.name

  security_rules = {
    allow_sql_from_app = {
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "1433"
      source_address_prefix      = "10.0.2.0/24"   # app subnet CIDR
      destination_address_prefix = "*"
    }
  }

  subnet_ids = {
    data = module.subnet_data.id
  }
}
```

### NSG applied to multiple subnets

```hcl
module "nsg_shared" {
  source = "./modules/Azure/networking/nsg"

  nsg_name            = "nsg-shared-services"
  location            = module.rg.location
  resource_group_name = module.rg.name

  security_rules = {
    allow_mgmt_inbound = {
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_ranges    = ["22", "3389"]
      source_address_prefixes    = ["10.0.100.0/24", "10.0.101.0/24"]
      destination_address_prefix = "*"
    }
  }

  subnet_ids = {
    mgmt    = module.subnet_mgmt.id
    bastion = module.subnet_bastion.id
  }
}
```

---

## Inputs

| Name | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| `nsg_name` | `string` | — | yes | Name of the Network Security Group |
| `location` | `string` | — | yes | Azure region |
| `resource_group_name` | `string` | — | yes | Resource group to deploy the NSG into |
| `security_rules` | `map(object)` | — | yes | Map of security rules (see below) |
| `subnet_ids` | `map(string)` | — | yes | Map of `name → subnet_id` to associate with this NSG |

### `security_rules` object (per map entry)

The map key becomes the rule name. All port/address fields are optional except where noted.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `priority` | `number` | yes | Rule priority (100–4096, lower = higher priority) |
| `direction` | `string` | yes | `Inbound` or `Outbound` |
| `access` | `string` | yes | `Allow` or `Deny` |
| `protocol` | `string` | yes | `Tcp`, `Udp`, `Icmp`, `Esp`, `Ah`, or `*` |
| `source_port_range` | `string` | no | Single port, range (`1024-65535`), or `*` |
| `source_port_ranges` | `list(string)` | no | Multiple individual ports or ranges |
| `destination_port_range` | `string` | no | Single port, range, or `*` |
| `destination_port_ranges` | `list(string)` | no | Multiple ports or ranges |
| `source_address_prefix` | `string` | no | CIDR, IP, service tag (e.g. `Internet`), or `*` |
| `source_address_prefixes` | `list(string)` | no | Multiple CIDRs or IPs |
| `destination_address_prefix` | `string` | no | CIDR, IP, service tag, or `*` |
| `destination_address_prefixes` | `list(string)` | no | Multiple CIDRs or IPs |

> Use either the singular (`_range` / `_prefix`) **or** plural (`_ranges` / `_prefixes`) form per field — not both.

---

## Outputs

| Name | Description |
|------|-------------|
| `id` | Resource ID of the NSG |
| `subnet_associations` | List of subnet map keys that the NSG was associated with |

---

## Notes

- **Priority gaps**: Leave gaps between priorities (e.g. 100, 200, 300) so rules can be inserted later without renumbering.
- **Implicit deny**: Azure adds an implicit `Deny All` at priority 65500. You don't need to add one unless you want it at a lower number to override other rules.
- **Service tags**: Use Azure service tags (`Internet`, `AzureLoadBalancer`, `VirtualNetwork`, `AzureCloud`, etc.) in address fields to avoid hardcoding IP ranges that Azure manages.
- **One NSG per subnet**: Azure only allows one NSG per subnet. If you associate a second NSG, it replaces the first.
