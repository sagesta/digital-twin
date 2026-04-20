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

variable "enable_linux_function_app" {
  type        = bool
  description = "Provision Linux App Service plan + Function App + blob role assignment. Set false when App Service quotas are zero (Dynamic/Basic/Standard/Premium) until Azure increases limits; you still get storage + optional OpenAI account."
  default     = true
}

variable "enable_openai_model_deployment" {
  type        = bool
  description = "Create the Azure OpenAI model deployment (gpt-4o / etc.). Set false to only create the Cognitive account so apply can succeed when model deployment fails (715 / quota); create deployment later in portal or re-enable and apply."
  default     = true
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
  description = "Azure OpenAI deployment name (what clients pass as the model parameter). Default matches openai_model_name for clarity."
  default     = "gpt-4o"
}

variable "openai_model_name" {
  type        = string
  description = "Base model to deploy. gpt-4o + GlobalStandard is widely available; use gpt-4o-mini + Standard only where your region supports that combo (see Azure models doc)."
  default     = "gpt-4o"
}

variable "openai_model_version" {
  type        = string
  description = "Model version (must match openai_model_name and openai_deployment_scale_type). gpt-4o with GlobalStandard commonly uses 2024-11-20."
  default     = "2024-11-20"
}

variable "openai_deployment_capacity" {
  type        = number
  description = "Deployment capacity (TPM thousands). Use 1 first if apply returns 715 / quota errors."
  default     = 1
}

variable "openai_deployment_scale_type" {
  type        = string
  description = "Deployment SKU: GlobalStandard for gpt-4o in most regions; Standard for regional mini deployments where supported."
  default     = "GlobalStandard"
}

variable "functions_service_plan_sku_name" {
  type        = string
  description = "Linux App Service plan SKU (only when enable_linux_function_app is true). Default Y1 = consumption (dev/test; no always_on). Use B1/S1/P0v3/EP1 for dedicated or production-style (always_on, VNet, longer runs)."
  default     = "Y1"
}
