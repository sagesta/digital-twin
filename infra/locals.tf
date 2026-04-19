locals {
  resource_group_name_effective = coalesce(var.resource_group_name, "${var.project_name}-${var.environment}-rg")

  # Linux consumption Functions use Y1; dedicated SKUs (B1, EP1, …) allow always_on.
  functions_is_consumption_y1 = var.functions_service_plan_sku_name == "Y1"

  common_tags = {
    environment = var.environment
    project     = var.project_name
    managed_by  = "terraform"
  }

  # Storage account names: max 24 chars, lowercase letters and numbers only.
  storage_name_core = replace(lower("${var.project_name}${var.environment}"), "-", "")
  storage_account_name = substr(
    "${local.storage_name_core}${random_id.storage.hex}",
    0,
    24
  )

  # Azure static website always serves from the $web container; see README.
  memory_container_name = "memory"
}
