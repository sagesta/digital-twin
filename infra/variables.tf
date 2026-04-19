variable "subscription_id" {
  type        = string
  description = "Azure subscription ID where resources will be deployed."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group for all Digital Twin resources."
  default     = "digital-twin-rg"
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

variable "openai_gpt4o_model_version" {
  type        = string
  description = "Model version string for the gpt-4o deployment (region-specific availability may vary)."
  default     = "2024-11-20"
}

variable "openai_deployment_capacity" {
  type        = number
  description = "Deployment capacity (thousands of tokens per minute for GlobalStandard). Start low (e.g. 10) on new subscriptions; raise after quota increases."
  default     = 10
}

variable "openai_deployment_scale_type" {
  type        = string
  description = "Azure OpenAI deployment SKU name passed to the scale block (e.g. GlobalStandard for gpt-4o in many regions). Use Standard only if your region/model requires it."
  default     = "GlobalStandard"
}

variable "functions_service_plan_sku_name" {
  type        = string
  description = "Linux App Service plan SKU for Azure Functions. Y1 is consumption (lowest cost but requires Dynamic VMs quota). B1 is a small dedicated plan and avoids consumption quota issues."
  default     = "B1"
}
