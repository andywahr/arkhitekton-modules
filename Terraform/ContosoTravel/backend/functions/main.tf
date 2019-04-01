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

variable "keyVaultId" {
  type = "string"
}

variable "storageConnectionString" {
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

variable "servicePrincipalObjectId" {
  type = "string"
}

variable "servicePrincipalClientId" {
  type = "string"
}

variable "servicePrincipalSecretName" {
  type = "string"
}

variable "web" {
  type = "string"
}

variable "platform" {
  type = "string"
}

resource "azurerm_app_service_plan" "serviceAppServicePlan" {
  name                = "asp-contosotravel-${var.namePrefix}-service"
  location            = "${var.location}"
  resource_group_name = "${var.resourceGroupName}"
  kind                = "FunctionApp"

  sku {
    tier = "Standard"
    size = "S1"
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
  
  site_config {
     always_on = true
  }   
   
  app_settings {
    "APPINSIGHTS_INSTRUMENTATIONKEY" = "${var.appInsightsKey}"
    "KeyVaultUrl"                    = "${var.keyVaultUrl}"
    "KeyVaultAccountName"            = "${var.keyVaultAccountName}"
    "WEBSITE_NODE_DEFAULT_VERSION"   = "10.0.0"
    "FUNCTIONS_WORKER_RUNTIME"       = "${var.platform == "servicesnodekubeservicebus" ? "node" : "dotnet"}"
    "ServiceBusConnection"           = "${replace(var.serviceConnectionString, ";EntityPath.+", "")}"
  }

}

#resource "azurerm_monitor_diagnostic_setting" "serviceDiag" {
#  name               = "${var.namePrefix}-serviceDiag"
#  target_resource_id = "${azurerm_function_app.service.id}"
#  storage_account_id = "${var.storageAccountId}"
#  log_analytics_workspace_id = "${var.logAnalyticsId}"
#
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

resource "azurerm_key_vault_access_policy" "serviceKeyVaultPolicy" {
  key_vault_id        = "${var.keyVaultId}"

  tenant_id = "${data.azurerm_client_config.current.tenant_id}"
  object_id = "${azurerm_function_app.service.identity.0.principal_id}"

  secret_permissions = [
    "get",
    "list",
  ]
}