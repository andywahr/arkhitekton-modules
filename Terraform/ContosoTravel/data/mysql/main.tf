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
  length = 11
  special = false
}

resource "random_string" "dataAdministratorLoginPassword" {
  length = 32
  special = true
}

resource "random_string" "dataAccountUserName" {
  length = 11
  special = false
}

resource "random_string" "dataAccountPassword" {
  length = 32
  special = true
}

resource "azurerm_mysql_server" "mysqlServer" {
  name                         = "contosotravel-${var.namePrefix}"
  resource_group_name          = "${var.resourceGroupName}"
  location                     = "${var.location}"
  version                      = "5.7"
  ssl_enforcement              = "Enabled"  
  administrator_login          = "mysql${random_string.dataAdministratorLogin.result}"
  administrator_login_password = "${random_string.dataAdministratorLoginPassword.result}"


  sku {
    name     = "GP_Gen5_4"
    capacity = 4
    tier     = "GeneralPurpose"
    family   = "Gen5"
  }

  storage_profile {
    storage_mb            = 5120
    backup_retention_days = 7
    geo_redundant_backup  = "Disabled"
  }
}

resource "azurerm_mysql_database" "mysqlServerDatabase" {
  name                = "ContosoTravel"
  resource_group_name = "${var.resourceGroupName}"
  server_name         = "${azurerm_mysql_server.mysqlServer.name}"
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}

resource "azurerm_mysql_firewall_rule" "sqlAllAzureServices" {
  name                = "sqlAllAzureServicesRule"
  resource_group_name = "${var.resourceGroupName}"
  server_name         = "${azurerm_mysql_server.mysqlServer.name}"
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}
resource "azurerm_mysql_firewall_rule" "sqlAllServices" {
  name                = "sqlAllAzureServicesRule"
  resource_group_name = "${var.resourceGroupName}"
  server_name         = "${azurerm_mysql_server.mysqlServer.name}"
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "255.255.255.255"
}

resource "azurerm_mysql_virtual_network_rule" "sqlAppVnetRule" {
  name                = "mysql-vnet-rule"
  resource_group_name = "${var.resourceGroupName}"
  server_name         = "${azurerm_mysql_server.mysqlServer.name}"
  subnet_id           = "${var.vnetId}"
}

resource "azurerm_mysql_virtual_network_rule" "sqlAciVnetRule" {
  name                = "mysql-vnet-rule"
  resource_group_name = "${var.resourceGroupName}"
  server_name         = "${azurerm_mysql_server.mysqlServer.name}"
  subnet_id           = "${var.aciVnetId}"
}

resource "azurerm_monitor_diagnostic_setting" "dataDiag" {
  name               = "${var.namePrefix}-dataDiag"
  target_resource_id = "${azurerm_mysql_server.mysqlServer.id}"
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
  value    = "MySQL"
  key_vault_id = "${var.keyVaultId}"
}

resource "azurerm_key_vault_secret" "dataAccountName" {
  name     = "ContosoTravel--DataAccountName"
  value    = "${azurerm_mysql_server.mysqlServer.name}"
  key_vault_id = "${var.keyVaultId}"
}

resource "azurerm_key_vault_secret" "databaseName" {
  name     = "ContosoTravel--DatabaseName"
  value    = "ContosoTravel"
  key_vault_id = "${var.keyVaultId}"
}

resource "azurerm_key_vault_secret" "dataAdministratorLogin" {
  name     = "ContosoTravel--DataAdministratorLogin"
  value    = "mysql${random_string.dataAdministratorLogin.result}"
  key_vault_id = "${var.keyVaultId}"
}

resource "azurerm_key_vault_secret" "dataAdministratorLoginPassword" {
  name     = "ContosoTravel--DataAdministratorLoginPassword"
  value    = "${random_string.dataAdministratorLoginPassword.result}"
  key_vault_id = "${var.keyVaultId}"
}

resource "azurerm_key_vault_secret" "dataAccountUserName" {
  name     = "ContosoTravel--DataAccountUserName"
  value    = "mysql${random_string.dataAccountUserName.result}"
  key_vault_id = "${var.keyVaultId}"
}

resource "azurerm_key_vault_secret" "dataAccountPassword" {
  name     = "ContosoTravel--DataAccountPassword"
  value    = "${random_string.dataAccountPassword.result}"
  key_vault_id = "${var.keyVaultId}"
}
