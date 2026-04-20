# Preserve state addresses when adding `count = … ? 1 : 0` to these resources.
moved {
  from = azurerm_service_plan.functions
  to   = azurerm_service_plan.functions[0]
}

moved {
  from = azurerm_linux_function_app.main
  to   = azurerm_linux_function_app.main[0]
}

moved {
  from = azurerm_role_assignment.function_memory_blob_contributor
  to   = azurerm_role_assignment.function_memory_blob_contributor[0]
}

moved {
  from = azurerm_cognitive_deployment.gpt4o
  to   = azurerm_cognitive_deployment.gpt4o[0]
}
