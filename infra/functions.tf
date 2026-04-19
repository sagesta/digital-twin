resource "azurerm_service_plan" "functions" {
  name                = "${var.project_name}-${var.environment}-functions-plan"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.functions_service_plan_sku_name

  tags = local.common_tags
}

resource "azurerm_linux_function_app" "main" {
  name                 = "${var.project_name}-${var.environment}-functions"
  resource_group_name  = azurerm_resource_group.main.name
  location             = var.location
  service_plan_id      = azurerm_service_plan.functions.id
  storage_account_name = azurerm_storage_account.main.name
  # Required by the Functions host for internal state; conversation memory uses managed identity + Blob API.
  storage_account_access_key = azurerm_storage_account.main.primary_access_key

  functions_extension_version = "~4"

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_stack {
      python_version = "3.11"
    }
    always_on = !local.functions_is_consumption_y1
    cors {
      allowed_origins     = ["*"]
      support_credentials = false
    }
  }

  app_settings = {
    AzureWebJobsStorage              = azurerm_storage_account.main.primary_connection_string
    FUNCTIONS_WORKER_RUNTIME         = "python"
    AZURE_OPENAI_ENDPOINT            = azurerm_cognitive_account.openai.endpoint
    AZURE_OPENAI_API_KEY             = azurerm_cognitive_account.openai.primary_access_key
    AZURE_OPENAI_DEPLOYMENT         = azurerm_cognitive_deployment.gpt4o.name
    AZURE_STORAGE_ACCOUNT_URL        = azurerm_storage_account.main.primary_blob_endpoint
    MEMORY_BLOB_CONTAINER             = local.memory_container_name
    PYTHON_ENABLE_WORKER_EXTENSIONS  = "1"
  }

  tags = local.common_tags

  depends_on = [
    azurerm_cognitive_deployment.gpt4o
  ]
}

resource "azurerm_role_assignment" "function_memory_blob_contributor" {
  scope = "${azurerm_storage_account.main.id}/blobServices/default/containers/${azurerm_storage_container.memory.name}"

  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_function_app.main.identity[0].principal_id

  depends_on = [
    azurerm_linux_function_app.main,
    azurerm_storage_container.memory
  ]
}
