output "resource_group_name" {
  description = "Resource group containing Digital Twin infrastructure."
  value       = azurerm_resource_group.main.name
}

output "front_door_endpoint_hostname" {
  description = "Front Door hostname when enable_azure_front_door is true; otherwise null."
  value       = var.enable_azure_front_door ? azurerm_cdn_frontdoor_endpoint.main[0].host_name : null
}

output "front_door_endpoint_url" {
  description = "Full https URL on Front Door when enabled; otherwise null (use static_website_url)."
  value       = var.enable_azure_front_door ? "https://${azurerm_cdn_frontdoor_endpoint.main[0].host_name}" : null
}

output "static_website_url" {
  description = "Direct https URL for the storage static website (always set; use when Front Door is disabled)."
  value       = "https://${azurerm_storage_account.main.primary_web_host}"
}

output "function_app_default_hostname" {
  description = "Default Azure Functions hostname (append /api/<route> for HTTP triggers)."
  value       = azurerm_linux_function_app.main.default_hostname
}

output "function_app_url" {
  description = "Base URL for the Function App."
  value       = "https://${azurerm_linux_function_app.main.default_hostname}"
}

output "function_app_name" {
  description = "Function App name (GitHub secret AZURE_FUNCTION_APP_NAME)."
  value       = azurerm_linux_function_app.main.name
}

output "openai_endpoint" {
  description = "Azure OpenAI resource endpoint URL."
  value       = azurerm_cognitive_account.openai.endpoint
}

output "openai_account_name" {
  description = "Azure OpenAI account resource name."
  value       = azurerm_cognitive_account.openai.name
}

output "openai_primary_access_key" {
  description = "Primary key for the Azure OpenAI account (sensitive). Use for OPENAI_API_KEY GitHub secret if needed."
  value       = azurerm_cognitive_account.openai.primary_access_key
  sensitive   = true
}

output "storage_account_name" {
  description = "Storage account name (GitHub secret AZURE_STORAGE_ACCOUNT_NAME for static uploads)."
  value       = azurerm_storage_account.main.name
}

output "static_website_host" {
  description = "Direct storage static website host (prefer Front Door URL for production tests)."
  value       = azurerm_storage_account.main.primary_web_host
}

output "memory_container_name" {
  description = "Private container used for conversation JSON blobs."
  value       = azurerm_storage_container.memory.name
}
