variable "namePrefix" {
  type = "string"
}

variable "location" {
  type = "string"
}

variable "resourceGroupName" {
  type = "string"
}

variable "webSiteFQDN" {
  type = "string"
}

variable "enabled" {
  type = "string"
}

resource "azurerm_traffic_manager_profile" "trafficManager" {
  name                   = "trafficmanager-contosotravel-${lower(var.namePrefix)}"
  resource_group_name    = "${var.resourceGroupName}"
  traffic_routing_method = "Performance"
  count               = "${var.enabled == "true" ? 1 : 0}"

  dns_config {
    relative_name = "trafficmanager-contosotravel-${lower(var.namePrefix)}"
    ttl           = 300
  }

  monitor_config {
    protocol = "http"
    port     = 80
    path     = "/"
  }
}

resource "azurerm_traffic_manager_endpoint" "trafficManagerEndpoint" {
  name                = "trafficManagerEndpoint-${var.namePrefix}"
  endpoint_location   = "${var.location}"
  resource_group_name = "${var.resourceGroupName}"
  profile_name        = "${azurerm_traffic_manager_profile.trafficManager.name}"
  type                = "externalEndpoints"
  target              = "${var.webSiteFQDN}"
  weight              = 100
  count               = "${var.enabled == "true" ? 1 : 0}"
}

output "webSiteFQDN" {
  value = "${element(concat(azurerm_traffic_manager_profile.trafficManager.*.fqdn, list("")), 0)}"
}