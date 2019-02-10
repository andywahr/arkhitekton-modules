
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

resource "azurerm_public_ip" "appGatewayPIP" {
  name                = "${var.namePrefix}-wafappgateway-pip"
  location            = "${var.location}"
  resource_group_name = "${var.resourceGroupName}"   
  allocation_method   = "Dynamic"
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

resource "azurerm_application_gateway" "network" {
  name                = "${var.namePrefix}-wafappgateway"
  location            = "${var.location}"
  resource_group_name = "${var.resourceGroupName}" 

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
    name = "${local.backend_address_pool_name}"
    fqdn_list = ["${var.webSiteFQDN}"]
  }

  backend_http_settings {
    name                  = "${local.http_setting_name}"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
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
    name = "HTTPProb"
    protocol = "Http"
    path = "/"
    interval  = 30
    timeout = 30
    unhealthy_threshold = 3
    pick_host_name_from_backend_http_settings = true
    match {
        body = ""
        status_code = ["200-399"]
    }
  }
}