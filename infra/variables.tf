variable "subscription_id" {
  type        = string
  description = "Azure subscription ID where resources will be deployed."
}

variable "resource_group_name" {
  type        = string
  nullable    = true
  default     = null
  description = "Resource group name for this stack. Leave null to use \"{project_name}-{environment}-rg\" (default: digitaltwin-dev-rg). Set explicitly if you import or must reuse a specific name."
}

variable "location" {
  type        = string
  description = "Azure region for every resource in this stack (resource group, storage, Functions, OpenAI). Must match management-group Azure Policy allowed locations when applicable. Pick a region where Azure OpenAI supports your model; GitHub Actions can set repository variable AZURE_LOCATION (maps to TF_VAR_location)."
  default     = "eastus"
}

variable "enable_azure_front_door" {
  type        = bool
  description = "Provision Azure Front Door Standard. Set false for lowest cost or when the subscription blocks Front Door; use the storage static website URL when false."
  default     = false
}

variable "project_name" {
  type        = string
  description = "Short prefix used in resource names; lowercase letters, numbers, hyphens only where allowed."
  default     = "digitaltwin"
}

variable "environment" {
  type        = string
  description = "Deployment stage label used in naming and tags (e.g. dev, prod)."
  default     = "dev"
}

variable "openai_api_key" {
  type        = string
  sensitive   = true
  default     = null
  nullable    = true
  description = "Not required for apply: Terraform creates the Azure OpenAI account and wires its key into the Function App. Use terraform output to read the key for GitHub secrets or local tools. Leave null unless you add custom logic later."
}

variable "openai_account_use_random_name_suffix" {
  type        = bool
  description = "When true, the OpenAI Cognitive Services account name includes a stable random suffix to avoid 409 FlagMustBeSetForRestore if Azure still holds a soft-deleted account with the same base name. The azurerm provider has no restore flag on this resource; set false only after purging or restoring the deleted account in Azure."
  default     = true
}

variable "openai_deployment_name" {
  type        = string
  description = "Azure OpenAI deployment name (what clients pass as the model parameter). Default gpt-4o matches function-app defaults even when the underlying model is gpt-4o-mini."
  default     = "gpt-4o"
}

variable "openai_model_name" {
  type        = string
  description = "Base model to deploy (e.g. gpt-4o-mini for broad subscription availability; gpt-4o if your subscription has access)."
  default     = "gpt-4o-mini"
}

variable "openai_model_version" {
  type        = string
  description = "Model version string (region and model specific). For gpt-4o-mini, 2024-07-18 is widely available."
  default     = "2024-07-18"
}

variable "openai_deployment_capacity" {
  type        = number
  description = "Deployment capacity (TPM thousands for Standard / per docs for GlobalStandard). Start low on new subscriptions."
  default     = 10
}

variable "openai_deployment_scale_type" {
  type        = string
  description = "Deployment scale type / SKU name. Standard works for gpt-4o-mini; gpt-4o often needs GlobalStandard in supported regions."
  default     = "Standard"
}

variable "functions_service_plan_sku_name" {
  type        = string
  description = "Linux App Service plan for Functions. Y1 = consumption (no Basic VM quota). B1 = dedicated Basic (requires Basic VM regional quota; use if Y1 Dynamic VM quota is 0)."
  default     = "Y1"
}
