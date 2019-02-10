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

variable "storageConnectionString" {
  type = "string"
}

resource "azurerm_app_service_plan" "serviceAppServicePlan" {
  name                = "asp-contosotravel-${var.namePrefix}-service"
  location            = "${var.location}"
  resource_group_name = "${var.resourceGroupName}"
  kind                = "FunctionApp"

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_function_app" "service" {
  name                      = "contosotravel-${var.namePrefix}-service"
  location                  = "${var.location}"
  resource_group_name       = "${var.resourceGroupName}"
  app_service_plan_id       = "${azurerm_app_service_plan.serviceAppServicePlan.id}"
  storage_connection_string = "${var.storageConnectionString}"
  version                   = "~2"
  identity {
    type = "SystemAssigned"
  }

  app_settings {
    "APPINSIGHTS_INSTRUMENTATIONKEY" = "${var.appInsightsKey}"
    "KeyVaultUrl"                    = "${var.keyVaultUrl}"
    "KeyVaultAccountName"            = "${var.keyVaultAccountName}"
    "WEBSITE_NODE_DEFAULT_VERSION"   = "10.6.0"
    "FUNCTIONS_WORKER_RUNTIME"       = "dotnet"
    "ServiceBusConnection"           = "${var.serviceConnectionString}"
  }
}

resource "azurerm_key_vault_access_policy" "webKeyVaultPolicy" {
  vault_name          = "${var.keyVaultAccountName}"
  resource_group_name = "${var.resourceGroupName}"

  tenant_id = "${data.azurerm_client_config.current.tenant_id}"
  object_id = "${azurerm_function_app.service.identity.0.principal_id}"

  secret_permissions = [
    "get",
    "list",
  ]
}