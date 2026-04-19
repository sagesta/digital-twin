resource "azurerm_storage_account" "main" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  allow_nested_items_to_be_public = true
  min_tls_version                 = "TLS1_2"

  static_website {
    index_document     = "index.html"
    error_404_document = "404.html"
  }

  tags = local.common_tags
}

# Static website configuration creates the $web container automatically.

# Optional logical "frontend" container (private) for artifacts; the live site is still served from $web.
resource "azurerm_storage_container" "frontend" {
  name                  = "frontend"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "memory" {
  name                  = local.memory_container_name
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}
