# Azure Front Door Standard is not available on Azure for Students / Free Trial.
# Set var.enable_azure_front_door = true on a PAYG subscription. Static site still works via storage primary_web_host.

resource "azurerm_cdn_frontdoor_profile" "main" {
  count = var.enable_azure_front_door ? 1 : 0

  name                = "${var.project_name}-${var.environment}-afd"
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Standard_AzureFrontDoor"

  tags = local.common_tags
}

resource "azurerm_cdn_frontdoor_endpoint" "main" {
  count = var.enable_azure_front_door ? 1 : 0

  name                     = "${var.project_name}-${var.environment}-ep"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main[0].id

  tags = local.common_tags
}

resource "azurerm_cdn_frontdoor_origin_group" "static_site" {
  count = var.enable_azure_front_door ? 1 : 0

  name                     = "${var.project_name}-${var.environment}-og"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main[0].id
  session_affinity_enabled = false

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    interval_in_seconds = 120
    path                = "/"
    protocol            = "Https"
    request_type        = "HEAD"
  }
}

resource "azurerm_cdn_frontdoor_origin" "static_site" {
  count = var.enable_azure_front_door ? 1 : 0

  name                          = "${var.project_name}-${var.environment}-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.static_site[0].id
  enabled                       = true

  host_name          = azurerm_storage_account.main.primary_web_host
  origin_host_header = azurerm_storage_account.main.primary_web_host
  priority           = 1
  weight             = 1000

  certificate_name_check_enabled = false
  http_port                      = 80
  https_port                     = 443
}

resource "azurerm_cdn_frontdoor_route" "static_site" {
  count = var.enable_azure_front_door ? 1 : 0

  name                          = "${var.project_name}-${var.environment}-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.main[0].id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.static_site[0].id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.static_site[0].id]

  enabled                = true
  forwarding_protocol    = "MatchRequest"
  https_redirect_enabled = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]

  link_to_default_domain = true

  cache {
    query_string_caching_behavior = "IgnoreQueryString"
    compression_enabled           = true
    content_types_to_compress = [
      "application/eot",
      "application/font",
      "application/font-sfnt",
      "application/javascript",
      "application/json",
      "application/opentype",
      "application/otf",
      "application/pkcs7-mime",
      "application/truetype",
      "application/ttf",
      "application/vnd.ms-fontobject",
      "application/xhtml+xml",
      "application/xml",
      "application/xml+rss",
      "application/x-font-opentype",
      "application/x-font-truetype",
      "application/x-font-ttf",
      "application/x-httpd-cgi",
      "application/x-javascript",
      "application/x-mpegurl",
      "application/x-opentype",
      "application/x-otf",
      "application/x-perl",
      "application/x-ttf",
      "font/eot",
      "font/opentype",
      "font/otf",
      "font/ttf",
      "image/svg+xml",
      "text/css",
      "text/csv",
      "text/html",
      "text/javascript",
      "text/js",
      "text/plain",
      "text/richtext",
      "text/tab-separated-values",
      "text/xml",
    ]
  }

  depends_on = [
    azurerm_cdn_frontdoor_origin.static_site,
    azurerm_storage_account.main
  ]
}
