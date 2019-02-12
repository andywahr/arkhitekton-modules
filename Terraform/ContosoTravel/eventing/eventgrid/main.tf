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

variable "keyVaultPermId" {
  type = "string"
}


resource "azurerm_eventgrid_topic" "eventGrid" {
  name                = "eg-${var.namePrefix}-contosotravel"
  location            = "${var.location}"
  resource_group_name = "${var.resourceGroupName}"    
}

resource "azurerm_key_vault_secret" "servicesType" {
  name         = "ContosoTravel--ServicesType"
  value        = "EventGrid"
  key_vault_id = "${var.keyVaultId}"
}

resource "azurerm_key_vault_secret" "servicesMiddlewareAccountName" {
  name         = "ContosoTravel--ServicesMiddlewareAccountName"
  value        = "${azurerm_eventgrid_topic.eventGrid.name}"
  key_vault_id = "${var.keyVaultId}"
}

resource "azurerm_key_vault_secret" "serviceConnectionString" {
  name         = "ContosoTravel--ServiceConnectionString"
  value        = ""
  key_vault_id = "${var.keyVaultId}"
}

output "serviceAccountName" {
  value = "${azurerm_eventgrid_topic.eventGrid.name}"
}

output "serviceConnectionString" {
  value = ""
}

output "eventingConnectionString" {
  value = ""
}