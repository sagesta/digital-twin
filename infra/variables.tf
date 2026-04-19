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
  description = "Azure region for every resource in this stack (resource group, storage, Functions, OpenAI). Must match subscription or management-group Azure Policy allowed locations (otherwise apply fails with 403 / RequestDisallowedByAzure). Azure for Students often allows eastus, westus, centralus, westeurope, southeastasia. Pick a region where Azure OpenAI is available for your offer. In GitHub Actions, set repository variable AZURE_LOCATION to override the default via TF_VAR_location."
  default     = "eastus"
}

variable "enable_azure_front_door" {
  type        = bool
  description = "Provision Azure Front Door Standard. Set false on Azure for Students / Free Trial (Front Door is blocked). Use the storage static website URL when false."
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

variable "openai_gpt4o_model_version" {
  type        = string
  description = "Model version string for the gpt-4o deployment (region-specific availability may vary)."
  default     = "2024-11-20"
}

variable "openai_deployment_capacity" {
  type        = number
  description = "Tokens per minute (thousands) for Standard SKU gpt-4o deployment; raise if quota allows."
  default     = 30
}
