# Azure Storage Account Module

A reusable Terraform module for deploying Azure Storage Accounts with private networking, user-assigned managed identity, network ACLs, and optional Blob containers.

---

## Features

- Storage Account with user-assigned managed identity
- Enforced TLS 1.2 minimum
- Network rules defaulting to **Deny** — only explicitly allowed subnets (via service endpoints) can access the account
- `AzureServices` bypass enabled for trusted Microsoft services
- One or more private Blob containers created automatically
- Optional diagnostic log forwarding to an ADLS storage account
- Private Link support via `private_link_subnet_id` and DNS zone configuration

---

## Usage

```hcl
module "storage" {
  source = "./modules/Azure/storage-account"

  storage_account_name = "mystorageacctprod"
  resource_group_name  = "rg-data-prod"
  location             = "eastus"

  user_assigned_identity_id = azurerm_user_assigned_identity.this.id
  private_link_subnet_id    = module.subnet_private.id
  private_dns_zone_ids      = [azurerm_private_dns_zone.blob.id]

  allowed_subnet_ids = [
    module.subnet_app.id,
    module.subnet_data.id,
  ]

  storage_container_names = ["uploads", "exports", "archive"]
}
```

---

## Examples

### Basic — single container, one allowed subnet

```hcl
module "storage_basic" {
  source = "./modules/Azure/storage-account"

  storage_account_name = "devappstore01"
  resource_group_name  = module.rg.name
  location             = module.rg.location

  user_assigned_identity_id = azurerm_user_assigned_identity.this.id
  private_link_subnet_id    = module.subnet_private.id
  private_dns_zone_ids      = [azurerm_private_dns_zone.blob.id]

  allowed_subnet_ids = [module.subnet_app.id]

  storage_container_names = ["data"]
}
```

### Premium block blob storage (for high-throughput workloads)

```hcl
module "storage_premium" {
  source = "./modules/Azure/storage-account"

  storage_account_name = "prodappblob01"
  resource_group_name  = module.rg.name
  location             = module.rg.location

  account_tier     = "Premium"
  replication_type = "LRS"

  user_assigned_identity_id = azurerm_user_assigned_identity.this.id
  private_link_subnet_id    = module.subnet_private.id
  private_dns_zone_ids      = [azurerm_private_dns_zone.blob.id]

  allowed_subnet_ids = [module.subnet_app.id]

  storage_container_names = ["streaming-data", "checkpoints"]
}
```

### GRS replication for disaster recovery

```hcl
module "storage_grs" {
  source = "./modules/Azure/storage-account"

  storage_account_name = "prodbackupstore01"
  resource_group_name  = module.rg.name
  location             = module.rg.location

  account_tier     = "Standard"
  replication_type = "GRS"   # Geo-Redundant Storage

  user_assigned_identity_id = azurerm_user_assigned_identity.this.id
  private_link_subnet_id    = module.subnet_private.id
  private_dns_zone_ids      = [azurerm_private_dns_zone.blob.id]

  allowed_subnet_ids = [module.subnet_data.id]

  storage_container_names = ["backups", "snapshots"]
}
```

### With diagnostic logs forwarded to ADLS

```hcl
module "storage_with_diag" {
  source = "./modules/Azure/storage-account"

  storage_account_name = "prodappstore01"
  resource_group_name  = module.rg.name
  location             = module.rg.location

  user_assigned_identity_id = azurerm_user_assigned_identity.this.id
  private_link_subnet_id    = module.subnet_private.id
  private_dns_zone_ids      = [azurerm_private_dns_zone.blob.id]

  allowed_subnet_ids = [module.subnet_app.id]

  storage_container_names = ["app-data"]

  enable_adls_diagnostics  = true
  adls_storage_account_id  = module.adls_storage.storage_account_id
}
```

### Full example — identity, subnets, containers, and dependency chaining

```hcl
resource "azurerm_user_assigned_identity" "storage_identity" {
  name                = "id-storage-prod"
  location            = module.rg.location
  resource_group_name = module.rg.name
}

# Subnet with Microsoft.Storage service endpoint
module "subnet_data" {
  source               = "./modules/Azure/networking/subnet"
  name                 = "snet-data"
  resource_group_name  = module.rg.name
  virtual_network_name = module.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
}

module "storage" {
  source = "./modules/Azure/storage-account"

  storage_account_name = "prodmyappstore01"
  resource_group_name  = module.rg.name
  location             = module.rg.location

  account_tier     = "Standard"
  replication_type = "ZRS"

  user_assigned_identity_id = azurerm_user_assigned_identity.storage_identity.id
  private_link_subnet_id    = module.subnet_data.id
  private_dns_zone_ids      = [azurerm_private_dns_zone.blob.id]

  allowed_subnet_ids = [module.subnet_data.id]

  # Ensures the subnet's service endpoint is active before the storage ACL applies
  allowed_subnet_depends_on = [module.subnet_data]

  storage_container_names = ["raw", "processed", "archive"]
}
```

---

## Inputs

| Name | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| `storage_account_name` | `string` | — | yes | Storage account name (3–24 chars, lowercase letters and numbers only) |
| `resource_group_name` | `string` | — | yes | Resource group to deploy into |
| `location` | `string` | — | yes | Azure region |
| `user_assigned_identity_id` | `string` | `null` | yes* | Resource ID of the user-assigned managed identity |
| `private_link_subnet_id` | `string` | — | yes | Subnet ID for the Private Endpoint |
| `private_dns_zone_ids` | `list(string)` | — | yes | Private DNS Zone IDs to link (e.g. `privatelink.blob.core.windows.net`) |
| `account_tier` | `string` | `"Standard"` | no | `Standard` or `Premium` |
| `replication_type` | `string` | `"LRS"` | no | `LRS`, `ZRS`, `GRS`, `RAGRS`, `GZRS`, or `RAGZRS` |
| `storage_container_names` | `list(string)` | `["default-container"]` | no | Blob containers to create (private access) |
| `allowed_subnet_ids` | `list(string)` | `[]` | no | Subnet IDs permitted through the network ACL (requires `Microsoft.Storage` service endpoint on each subnet) |
| `allowed_subnet_depends_on` | `list(any)` | `[]` | no | Resources to depend on before applying network rules (use to sequence subnet endpoint activation) |
| `enable_adls_diagnostics` | `bool` | `false` | no | Enable diagnostic log forwarding to an ADLS storage account |
| `adls_storage_account_id` | `string` | `null` | no | Target storage account ID for diagnostic logs |

---

## Outputs

| Name | Description |
|------|-------------|
| `storage_account_id` | Resource ID of the storage account |

---

## Notes

- **Naming**: Storage account names must be globally unique across all of Azure, 3–24 lowercase alphanumeric characters, no hyphens.
- **Service endpoints**: Each subnet in `allowed_subnet_ids` must have `Microsoft.Storage` enabled as a service endpoint. Use `allowed_subnet_depends_on` to ensure the endpoint is active before the ACL is applied.
- **User-assigned identity**: The module always attaches a user-assigned managed identity. Ensure you create `azurerm_user_assigned_identity` separately and assign it appropriate RBAC roles (e.g. `Storage Blob Data Contributor`) after deployment.
- **Replication types**: `ZRS` (zone-redundant) is recommended for production in regions that support it. `GRS`/`GZRS` add cross-region redundancy for disaster recovery scenarios.
- **`public_network_access_enabled = true`**: The module currently sets this to `true` while using network ACLs to restrict access. If your security posture requires fully private access, update this to `false` and ensure all access goes through the Private Endpoint.
