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

resource "azurerm_key_vault_secret" "servicesType" {
  name         = "ContosoTravel--ServicesType"
  value        = "Http"
  key_vault_id = "${var.keyVaultId}"
}

resource "azurerm_key_vault_secret" "servicesMiddlewareAccountName" {
  name         = "ContosoTravel--ServicesMiddlewareAccountName"
  value        = "Http"
  key_vault_id = "${var.keyVaultId}"
}

resource "azurerm_key_vault_secret" "serviceConnectionString" {
  name         = "ContosoTravel--ServiceConnectionString"
  value        = ""
  key_vault_id = "${var.keyVaultId}"
}

output "serviceAccountName" {
  value = "Http"
}

output "serviceConnectionString" {
  value = ""
}

output "eventingConnectionString" {
  value = ""
}