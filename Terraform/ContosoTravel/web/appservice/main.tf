data "azurerm_client_config" "current" {}

variable "namePrefix" {
  type = "string"
}

variable "location" {
  type = "string"
}

variable "resourceGroupName" {
  type = "string"
}

variable "keyVaultUrl" {
  type = "string"
}

variable "keyVaultAccountName" {
  type = "string"
}

variable "keyVaultId" {
  type = "string"
}

variable "appInsightsKey" {
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

variable "vnetName" {
  type = "string"
}

variable "vnetId" {
  type = "string"
}

resource "azurerm_app_service_plan" "webSiteAppServicePlan" {
  name                = "asp-contosotravel-${var.namePrefix}-web"
  location            = "${var.location}"
  resource_group_name = "${var.resourceGroupName}"

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "webSite" {
  name                = "contosotravel-${var.namePrefix}-web"
  location            = "${var.location}"
  resource_group_name = "${var.resourceGroupName}"
  app_service_plan_id = "${azurerm_app_service_plan.webSiteAppServicePlan.id}"

  identity {
    type = "SystemAssigned"
  }

  app_settings {
    "APPINSIGHTS_INSTRUMENTATIONKEY" = "${var.appInsightsKey}"
    "KeyVaultUrl"                    = "${var.keyVaultUrl}"
    "KeyVaultAccountName"            = "${var.keyVaultAccountName}"
    "WEBSITE_NODE_DEFAULT_VERSION"   = "10.6.0"
  }

  site_config { 
    virtual_network_name = "${var.vnetName}"
  }
}

resource "azurerm_key_vault_access_policy" "webKeyVaultPolicy" {
  key_vault_id        = "${var.keyVaultId}"

  tenant_id = "${data.azurerm_client_config.current.tenant_id}"
  object_id = "${azurerm_app_service.webSite.identity.0.principal_id}"

  secret_permissions = [
    "get",
    "list",
  ]
}

#resource "azurerm_monitor_diagnostic_setting" "webDiag" {
#  name               = "${var.namePrefix}-webDiag"
#  target_resource_id = "${azurerm_app_service.webSite.id}"
#  storage_account_id = "${var.storageAccountId}"
#  log_analytics_workspace_id = "${var.logAnalyticsId}"

#  log {
#    category = "AuditEvent"
#    enabled  = true
#
#    retention_policy {
#      enabled = false
#    }
#  }
#
#  metric {
#    category = "AllMetrics"
#
#    retention_policy {
#      enabled = false
#    }
#  }
#}

output "webSiteFQDN" {
  value = "${azurerm_app_service.webSite.default_site_hostname}"
}

