
variable "namePrefix" {
  type = "string"
}

variable "location" {
   type = "string"
}

variable "resourceGroupName" {
   type = "string"
}

variable "keyVaultId" {
   type = "string"
}

variable "storageAccountId" {
  type = "string"
}

variable "logAnalyticsId" {
  type = "string"
}

resource "azurerm_servicebus_namespace" "serviceBus" {
  name                = "sb-${var.namePrefix}-contosotravel"
  location            = "${var.location}"
  resource_group_name = "${var.resourceGroupName}"   
  sku                 = "Standard"
}

resource "azurerm_monitor_diagnostic_setting" "serviceBusDiag" {
  name               = "${var.namePrefix}-serviceBusDiag"
  target_resource_id = "${azurerm_servicebus_namespace.serviceBus.id}"
  storage_account_id = "${var.storageAccountId}"
  log_analytics_workspace_id = "${var.logAnalyticsId}"
  
  log {
    category = "OperationalLogs"
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

resource "azurerm_servicebus_queue" "serviceBusQueue" {
  name                  = "PurchaseItinerary"
  resource_group_name = "${var.resourceGroupName}"   
  namespace_name        = "${azurerm_servicebus_namespace.serviceBus.name}"
  default_message_ttl   = "P1D"
  max_size_in_megabytes = "1024"

  enable_partitioning = false
}

resource "azurerm_servicebus_queue_authorization_rule" "serviceBusReaderRule" {
  name                = "PurchaseItinerary-Reader"
  namespace_name      = "${azurerm_servicebus_namespace.serviceBus.name}"
  queue_name          = "${azurerm_servicebus_queue.serviceBusQueue.name}"
  resource_group_name = "${var.resourceGroupName}"   

  listen = true
  send   = false
  manage = false
}

resource "azurerm_servicebus_queue_authorization_rule" "serviceBusWriterRule" {
  name                = "PurchaseItinerary-Writer"
  namespace_name      = "${azurerm_servicebus_namespace.serviceBus.name}"
  queue_name          = "${azurerm_servicebus_queue.serviceBusQueue.name}"
  resource_group_name = "${var.resourceGroupName}"   

  listen = false
  send   = true
  manage = false
}


resource "azurerm_key_vault_secret" "servicesType" {
  name         = "ContosoTravel--ServicesType"
  value        = "ServiceBus"
  key_vault_id = "${var.keyVaultId}"
}

resource "azurerm_key_vault_secret" "servicesMiddlewareAccountName" {
  name         = "ContosoTravel--ServicesMiddlewareAccountName"
  value        = "${azurerm_servicebus_namespace.serviceBus.name}"
  key_vault_id = "${var.keyVaultId}"
}

resource "azurerm_key_vault_secret" "serviceConnectionString" {
  name         = "ContosoTravel--ServiceConnectionString"
  value        = "${azurerm_servicebus_queue_authorization_rule.serviceBusWriterRule.primary_connection_string}"
  key_vault_id = "${var.keyVaultId}"
}

output "serviceAccountName" {
  value = "${azurerm_servicebus_namespace.serviceBus.name}"
}

output "serviceConnectionString" {
  value = "${replace(azurerm_servicebus_queue_authorization_rule.serviceBusReaderRule.primary_connection_string, "EntityPath.+", "")}"
}

output "eventingConnectionString" {
  value = "${replace(azurerm_servicebus_queue_authorization_rule.serviceBusWriterRule.primary_connection_string, "EntityPath.+", "")}"
}