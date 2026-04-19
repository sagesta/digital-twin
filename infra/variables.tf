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
  description = "Azure region for all resources. Azure for Students often restricts regions; try eastus if apply fails with RequestDisallowedByAzure. Confirm gpt-4o quota before apply."
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
