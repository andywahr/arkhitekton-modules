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

variable "serviceConnectionString" {
  type = "string"
}

variable "keyVaultUrl" {
  type = "string"
}

variable "keyVaultAccountName" {
  type = "string"
}

variable "appInsightsKey" {
  type = "string"
}

resource "azurerm_app_service_plan" "webSiteAppServicePlan" {
  name                = "asp-${var.namePrefix}"
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
}

resource "azurerm_key_vault_access_policy" "webKeyVaultPolicy" {
  vault_name          = "${var.keyVaultAccountName}"
  resource_group_name = "${var.resourceGroupName}"

  tenant_id = "${data.azurerm_client_config.current.tenant_id}"
  object_id = "${azurerm_app_service.webSite.identity.0.principal_id}"

  secret_permissions = [
    "get",
    "list",
  ]
}