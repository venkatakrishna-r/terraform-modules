data "azurerm_client_config" "current" {}

resource "azurerm_storage_account" "this" {
  name                          = var.storage_account_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  account_tier                  = var.account_tier
  account_replication_type      = var.replication_type
  public_network_access_enabled = true # Disable public access
  min_tls_version               = "TLS1_2" #todo check
  identity {
    type         = "UserAssigned"
    identity_ids = [var.user_assigned_identity_id]
  }

  network_rules {
    default_action             = "Deny"  # Blocks all traffic unless explicitly allowed
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = var.allowed_subnet_ids
   }
 
  # Force dependency
  depends_on = [
    var.allowed_subnet_depends_on
  ]
}

resource "azurerm_storage_container" "this" {
  for_each              = toset(var.storage_container_names)
  name                  = each.value
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
  depends_on            = [azurerm_storage_account.this,
                           azurerm_role_assignment.this
                          ]
}