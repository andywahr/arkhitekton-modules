variable "namePrefix" {
  type = "string"
}

variable "location" {
  type = "string"
}

variable "resourceGroupName" {
  type = "string"
}

variable "vnetId" {
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

variable "keyVaultId" {
  type = "string"
}


resource "azurerm_cosmosdb_account" "cosmosdb" {
  name                = "contosotravel-${var.namePrefix}"
  location            = "${var.location}"
  resource_group_name = "${var.resourceGroupName}"
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  enable_automatic_failover = false
  is_virtual_network_filter_enabled = true
  ip_range_filter =  "0.0.0.0/24,1.1.1.1/24,104.42.195.92,40.76.54.131,52.176.6.30,52.169.50.45,52.187.184.26"
  consistency_policy {
    consistency_level = "Strong"
  }

  virtual_network_rule {
    id = "${var.vnetId}"
  }

  geo_location {
        location          = "${var.location}"
        failover_priority = 0
  }
}

resource "azurerm_monitor_diagnostic_setting" "dataDiag" {
  name               = "${var.namePrefix}-dataDiag"
  target_resource_id = "${azurerm_cosmosdb_account.cosmosdb.id}"
  storage_account_id = "${var.storageAccountId}"
  log_analytics_workspace_id = "${var.logAnalyticsId}"
  
  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}

resource "azurerm_key_vault_secret" "dataType" {
  name     = "ContosoTravel--DataType"
  value    = "CosmosSQL"
  key_vault_id = "${var.keyVaultId}"
}

resource "azurerm_key_vault_secret" "dataAccountName" {
  name     = "ContosoTravel--DataAccountName"
  value    = "${azurerm_cosmosdb_account.cosmosdb.name}"
  key_vault_id = "${var.keyVaultId}"
}

resource "azurerm_key_vault_secret" "databaseName" {
  name     = "ContosoTravel--DatabaseName"
  value    = "ContosoTravel"
  key_vault_id = "${var.keyVaultId}"
}

resource "azurerm_key_vault_secret" "dataAdministratorLogin" {
  name     = "ContosoTravel--DataAdministratorLogin"
  value    = ""
  key_vault_id = "${var.keyVaultId}"
}

resource "azurerm_key_vault_secret" "dataAdministratorLoginPassword" {
  name     = "ContosoTravel--DataAdministratorLoginPassword"
  value    = ""
  key_vault_id = "${var.keyVaultId}"
}

resource "azurerm_key_vault_secret" "dataAccountUserName" {
  name     = "ContosoTravel--DataAccountUserName"
  value    = ""
  key_vault_id = "${var.keyVaultId}"
}


resource "azurerm_key_vault_secret" "dataAccountPassword" {
  name     = "ContosoTravel--DataAccountPassword"
  value    = "${azurerm_cosmosdb_account.cosmosdb.primary_master_key}"
  key_vault_id = "${var.keyVaultId}"
}
