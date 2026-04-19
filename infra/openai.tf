resource "azurerm_cognitive_account" "openai" {
  name                = "${var.project_name}-${var.environment}-openai"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  kind                = "OpenAI"
  sku_name            = "S0"
  # Globally unique subdomain (alphanumeric only; max length enforced by API).
  custom_subdomain_name = substr(
    "${local.storage_name_core}${random_id.openai_sub.hex}",
    0,
    24
  )

  tags = local.common_tags
}

resource "azurerm_cognitive_deployment" "gpt4o" {
  name                 = "gpt-4o"
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = "gpt-4o"
    version = var.openai_gpt4o_model_version
  }

  scale {
    type     = "Standard"
    capacity = var.openai_deployment_capacity
  }
}
