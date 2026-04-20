resource "azurerm_cognitive_account" "openai" {
  # Account name must be globally unique. A soft-deleted account with the same name causes
  # 409 FlagMustBeSetForRestore on create; Terraform azurerm has no `restore` on this resource.
  name = var.openai_account_use_random_name_suffix ? "${var.project_name}-${var.environment}-openai-${random_id.openai_account.hex}" : "${var.project_name}-${var.environment}-openai"
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
  count = var.enable_openai_model_deployment ? 1 : 0

  name                 = var.openai_deployment_name
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = var.openai_model_name
    version = var.openai_model_version
  }

  scale {
    type     = var.openai_deployment_scale_type
    capacity = var.openai_deployment_capacity
  }
}
