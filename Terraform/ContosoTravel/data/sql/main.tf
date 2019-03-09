variable "namePrefix" {
  type = "string"
}

variable "location" {
  type = "string"
}

variable "resourceGroupName" {
  type = "string"
}

variable "aciVnetId" {
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

resource "random_string" "dataAdministratorLogin" {
  length = 16
  special = false
}

resource "random_string" "dataAdministratorLoginPassword" {
  length = 32
  special = true
}

resource "random_string" "dataAccountUserName" {
  length = 16
  special = false
}

resource "random_string" "dataAccountPassword" {
  length = 32
  special = true
}

resource "azurerm_sql_server" "sqlServer" {
  name                         = "contosotravel-sqlserver-${var.namePrefix}"
  resource_group_name          = "${var.resourceGroupName}"
  location                     = "${var.location}"
  version                      = "12.0"
  administrator_login          = "${random_string.dataAdministratorLogin.result}"
  administrator_login_password = "${random_string.dataAdministratorLoginPassword.result}"
}

resource "azurerm_sql_database" "sqlServerDatabase" {
  name                = "ContosoTravel"
  resource_group_name = "${var.resourceGroupName}"
  location            = "${var.location}"
  server_name         = "${azurerm_sql_server.sqlServer.name}"

  tags {
    environment = "production"
  }
}

resource "azurerm_sql_virtual_network_rule" "sqlAppVnetrule" {
  name                = "sql-vnet-rule-app"
  resource_group_name = "${var.resourceGroupName}"
  server_name         = "${azurerm_sql_server.sqlServer.name}"
  subnet_id           = "${var.vnetId}"
}

resource "azurerm_sql_virtual_network_rule" "sqlAciVnetrule" {
  name                = "sql-vnet-rule-aci"
  resource_group_name = "${var.resourceGroupName}"
  server_name         = "${azurerm_sql_server.sqlServer.name}"
  subnet_id           = "${var.aciVnetId}"
}
resource "azurerm_sql_firewall_rule" "sqlAllAzureServices" {
  name                = "sqlAllAzureServicesRule"
  resource_group_name = "${var.resourceGroupName}"
  server_name         = "${azurerm_sql_server.sqlServer.name}"
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_monitor_diagnostic_setting" "dataDiag" {
  name               = "${var.namePrefix}-dataDiag"
  target_resource_id = "${azurerm_sql_server.sqlServer.id}"
  storage_account_id = "${var.storageAccountId}"
  log_analytics_workspace_id = "${var.logAnalyticsId}"
  
  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}

#resource "azurerm_log_analytics_solution" "sqlInsights" {
#  solution_name         = "SQLInsights"
#  location            = "East US"
#  resource_group_name = "${var.resourceGroupName}"
#  workspace_resource_id = "${var.logAnalyticsId}"
#  workspace_name        = "${var.logAnalyticsName}"
#
#  plan {
#    publisher = "Microsoft"
#    product   = "OMSGallery/AzureSQLAnalytics"
#  }
#}

resource "azurerm_key_vault_secret" "dataType" {
  name     = "ContosoTravel--DataType"
  value    = "SQL"
  key_vault_id = "${var.keyVaultId}"
}

resource "azurerm_key_vault_secret" "dataAccountName" {
  name     = "ContosoTravel--DataAccountName"
  value    = "${azurerm_sql_server.sqlServer.name}"
  key_vault_id = "${var.keyVaultId}"
}

resource "azurerm_key_vault_secret" "databaseName" {
  name     = "ContosoTravel--DatabaseName"
  value    = "ContosoTravel"
  key_vault_id = "${var.keyVaultId}"
}

resource "azurerm_key_vault_secret" "dataAdministratorLogin" {
  name     = "ContosoTravel--DataAdministratorLogin"
  value    = "${random_string.dataAdministratorLogin.result}"
  key_vault_id = "${var.keyVaultId}"
}

resource "azurerm_key_vault_secret" "dataAdministratorLoginPassword" {
  name     = "ContosoTravel--DataAdministratorLoginPassword"
  value    = "${random_string.dataAdministratorLoginPassword.result}"
  key_vault_id = "${var.keyVaultId}"
}

resource "azurerm_key_vault_secret" "dataAccountUserName" {
  name     = "ContosoTravel--DataAccountUserName"
  value    = "${random_string.dataAccountUserName.result}"
  key_vault_id = "${var.keyVaultId}"
}

resource "azurerm_key_vault_secret" "dataAccountPassword" {
  name     = "ContosoTravel--DataAccountPassword"
  value    = "${random_string.dataAccountPassword.result}"
  key_vault_id = "${var.keyVaultId}"
}
