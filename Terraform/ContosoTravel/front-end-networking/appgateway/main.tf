variable "namePrefix" {
  type = "string"
}

variable "location" {
  type = "string"
}

variable "resourceGroupName" {
  type = "string"
}

variable "vnetName" {
  type = "string"
}

variable "subnetId" {
  type = "string"
}

variable "webSiteFQDN" {
  type = "string"
}

variable "enabled" {
  type = "string"
}

variable "storageAccountId" {
  type = "string"
}

variable "logAnalyticsId" {
  type = "string"
}

variable "logAnalyticsName" {
  type = "string"
}
resource "azurerm_public_ip" "appGatewayPIP" {
  name                = "${var.namePrefix}-wafappgateway-pip"
  location            = "${var.location}"
  resource_group_name = "${var.resourceGroupName}"
  allocation_method   = "Dynamic"
  count               = "${var.enabled == "true" ? 1 : 0}"
  domain_name_label   = "www-${lower(var.namePrefix)}-contosotravel"
}

# since these variables are re-used - a locals block makes this more maintainable
locals {
  backend_address_pool_name      = "${var.vnetName}-beap"
  frontend_port_name             = "${var.vnetName}-feport"
  frontend_ip_configuration_name = "${var.vnetName}-feip"
  http_setting_name              = "${var.vnetName}-be-htst"
  listener_name                  = "${var.vnetName}-httplstn"
  request_routing_rule_name      = "${var.vnetName}-rqrt"
}

resource "azurerm_application_gateway" "appGateway" {
  name                = "${var.namePrefix}-wafappgateway"
  location            = "${var.location}"
  resource_group_name = "${var.resourceGroupName}"
  count               = "${var.enabled == "true" ? 1 : 0}"

  sku {
    name     = "WAF_Medium"
    tier     = "WAF"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = "${var.subnetId}"
  }

  frontend_port {
    name = "${local.frontend_port_name}"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "${local.frontend_ip_configuration_name}"
    public_ip_address_id = "${azurerm_public_ip.appGatewayPIP.id}"
  }

  backend_address_pool {
    name  = "${local.backend_address_pool_name}"
    fqdns = ["${var.webSiteFQDN}"]
  }

  backend_http_settings {
    name                                = "${local.http_setting_name}"
    cookie_based_affinity               = "Disabled"
    port                                = 80
    protocol                            = "Http"
    request_timeout                     = 15
    probe_name                          = "HTTPProb"
    pick_host_name_from_backend_address = true
  }

  http_listener {
    name                           = "${local.listener_name}"
    frontend_ip_configuration_name = "${local.frontend_ip_configuration_name}"
    frontend_port_name             = "${local.frontend_port_name}"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "${local.request_routing_rule_name}"
    rule_type                  = "Basic"
    http_listener_name         = "${local.listener_name}"
    backend_address_pool_name  = "${local.backend_address_pool_name}"
    backend_http_settings_name = "${local.http_setting_name}"
  }

  probe {
    name                = "HTTPProb"
    protocol            = "Http"
    path                = "/"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    host                = "${var.webSiteFQDN}"

    match {
      body        = ""
      status_code = ["200-399"]
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "appGatewayDiag" {
  name               = "${var.namePrefix}-appGatewayDiag"
  target_resource_id = "${azurerm_application_gateway.appGateway.id}"
  storage_account_id = "${var.storageAccountId}"
  count               = "${var.enabled == "true" ? 1 : 0}"
  log_analytics_workspace_id = "${var.logAnalyticsId}"
  
  log {
    category = "AuditEvent"
    enabled  = true

    retention_policy {
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}

resource "azurerm_log_analytics_solution" "appGatewayInsights" {
  solution_name         = "AppGatewayInsights"
  location            = "East US"
  resource_group_name = "${var.resourceGroupName}"
  count               = "${var.enabled == "true" ? 1 : 0}"
  workspace_resource_id = "${var.logAnalyticsId}"
  workspace_name        = "${var.logAnalyticsName}"

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/AzureAppGatewayAnalytics"
  }
}
