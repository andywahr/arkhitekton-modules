variable "namePrefix" {
  type = "string"
}

variable "location" {
  type = "string"
}

variable "cdn" {
  type    = "string"
  default = "false"
}

variable "trafficmanager" {
  type    = "string"
  default = "false"
}

variable "apimgmt" {
  type    = "string"
  default = "false"
}

variable "firewall" {
  type    = "string"
  default = "false"
}

variable "appgateway" {
  type    = "string"
  default = "false"
}

variable "mobile" {
  type    = "string"
  default = "false"
}

variable "adb2c" {
  type    = "string"
  default = "false"
}

variable "streamanalytics" {
  type    = "string"
  default = "false"
}

variable "cognitiveservices" {
  type    = "string"
  default = "false"
}

variable "sqldatawarehouse" {
  type    = "string"
  default = "false"
}

variable "hdinsight" {
  type    = "string"
  default = "false"
}

variable "search" {
  type    = "string"
  default = "false"
}

variable "bot" {
  type    = "string"
  default = "false"
}

variable "resourceGroupName" {
  type = "string"
}

variable "my_principal_object_id" {
  type = "string"
  default = ""
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


resource "azurerm_resource_group" "resourceGroup" {
  name     = "${var.resourceGroupName}"
  location = "${var.location}"
}

resource "azurerm_log_analytics_workspace" "logAnalytics" {
  name                = "${var.namePrefix}logAnalytics"
  resource_group_name = "${azurerm_resource_group.resourceGroup.name}"
  location            = "East US"
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_log_analytics_solution" "azureActivity" {
  solution_name         = "AzureActivity"
  location              = "East US"
  resource_group_name   = "${azurerm_resource_group.resourceGroup.name}"
  workspace_resource_id = "${azurerm_log_analytics_workspace.logAnalytics.id}"
  workspace_name        = "${azurerm_log_analytics_workspace.logAnalytics.name}"

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/AzureActivity"
  }
}

resource "azurerm_virtual_network" "virtualNetwork" {
  name                = "${var.namePrefix}vnet"
  location            = "${azurerm_resource_group.resourceGroup.location}"
  resource_group_name = "${azurerm_resource_group.resourceGroup.name}"
  address_space       = ["10.0.0.0/8"]
}

resource "azurerm_subnet" "networkingSubnet" {
  name                 = "networkingSubnet"
  resource_group_name  = "${azurerm_resource_group.resourceGroup.name}"
  virtual_network_name = "${azurerm_virtual_network.virtualNetwork.name}"
  address_prefix       = "10.0.0.0/16"
}

resource "azurerm_subnet" "appSubnet" {
  name                 = "appSubnet"
  resource_group_name  = "${azurerm_resource_group.resourceGroup.name}"
  virtual_network_name = "${azurerm_virtual_network.virtualNetwork.name}"
  address_prefix       = "10.1.0.0/16"
  service_endpoints    = ["Microsoft.AzureActiveDirectory", "Microsoft.AzureCosmosDB", "Microsoft.EventHub", "Microsoft.KeyVault", "Microsoft.ServiceBus", "Microsoft.Sql", "Microsoft.Storage"]
}

resource "azurerm_storage_account" "storageAccount" {
  name                      = "${var.namePrefix}scontrav"
  location                  = "${azurerm_resource_group.resourceGroup.location}"
  resource_group_name       = "${azurerm_resource_group.resourceGroup.name}"
  enable_https_traffic_only = true
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  enable_blob_encryption    = true
  enable_file_encryption    = true

  #  network_rules {
  #    bypass                     = ["AzureServices", "Logging", "Metrics"]
  #    virtual_network_subnet_ids = ["${azurerm_subnet.appSubnet.id}"]
  #  }
}

resource "azurerm_application_insights" "appInsights" {
  name                = "${var.namePrefix}appInsightContosoTravel"
  location            = "${azurerm_resource_group.resourceGroup.location}"
  resource_group_name = "${azurerm_resource_group.resourceGroup.name}"
  application_type    = "Web"
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "keyVault" {
  name                = "kv${var.namePrefix}"
  location            = "${azurerm_resource_group.resourceGroup.location}"
  resource_group_name = "${azurerm_resource_group.resourceGroup.name}"
  tenant_id           = "${data.azurerm_client_config.current.tenant_id}"

  sku {
    name = "standard"
  }
}

resource "azurerm_monitor_diagnostic_setting" "keyVaultDiag" {
  name                       = "${var.namePrefix}-keyVaultDiag"
  target_resource_id         = "${azurerm_key_vault.keyVault.id}"
  storage_account_id         = "${azurerm_storage_account.storageAccount.id}"
  log_analytics_workspace_id = "${azurerm_log_analytics_workspace.logAnalytics.id}"

  log {
    category = "AuditEvent"
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

resource "azurerm_key_vault_access_policy" "deployKeyVaultPolicy" {
  key_vault_id = "${azurerm_key_vault.keyVault.id}"

  tenant_id = "${data.azurerm_client_config.current.tenant_id}"
  object_id = "${data.azurerm_client_config.current.service_principal_object_id == "" ? var.my_principal_object_id : data.azurerm_client_config.current.service_principal_object_id}"

  secret_permissions = [
    "set",
    "get",
  ]
}

resource "azurerm_key_vault_secret" "subscriptionId" {
  name         = "ContosoTravel--SubscriptionId"
  value        = "${data.azurerm_client_config.current.subscription_id}"
  key_vault_id = "${azurerm_key_vault.keyVault.id}"
  depends_on   = ["azurerm_key_vault_access_policy.deployKeyVaultPolicy"]
}

resource "azurerm_key_vault_secret" "tenantId" {
  name         = "ContosoTravel--SubscriptionId"
  value        = "${data.azurerm_client_config.current.tenant_id}"
  key_vault_id = "${azurerm_key_vault.keyVault.id}"
  depends_on   = ["azurerm_key_vault_access_policy.deployKeyVaultPolicy"]
}

resource "azurerm_key_vault_secret" "resourceGroupName" {
  name         = "ContosoTravel--ResourceGroupName"
  value        = "${azurerm_resource_group.resourceGroup.name}"
  key_vault_id = "${azurerm_key_vault.keyVault.id}"
  depends_on   = ["azurerm_key_vault_access_policy.deployKeyVaultPolicy"]
}

resource "azurerm_log_analytics_solution" "keyVaultAnalytics" {
  solution_name         = "KeyVaultAnalytics"
  location              = "East US"
  resource_group_name   = "${azurerm_resource_group.resourceGroup.name}"
  workspace_resource_id = "${azurerm_log_analytics_workspace.logAnalytics.id}"
  workspace_name        = "${azurerm_log_analytics_workspace.logAnalytics.name}"

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/KeyVaultAnalytics"
  }
}

module "eventing" {
  namePrefix        = "${var.namePrefix}"
  location          = "${var.location}"
  resourceGroupName = "${azurerm_resource_group.resourceGroup.name}"
  keyVaultId        = "${azurerm_key_vault.keyVault.id}"
  storageAccountId  = "${azurerm_storage_account.storageAccount.id}"
  logAnalyticsId    = "${azurerm_log_analytics_workspace.logAnalytics.id}"
  keyVaultPermId    = "${azurerm_key_vault_access_policy.deployKeyVaultPolicy.id}"
}

module "service" {
  namePrefix              = "${var.namePrefix}"
  location                = "${var.location}"
  resourceGroupName       = "${azurerm_resource_group.resourceGroup.name}"
  serviceConnectionString = "${module.eventing.serviceConnectionString}"
  keyVaultUrl             = "${azurerm_key_vault.keyVault.vault_uri}"
  keyVaultAccountName     = "${azurerm_key_vault.keyVault.name}"
  keyVaultId              = "${azurerm_key_vault.keyVault.id}"
  appInsightsKey          = "${azurerm_application_insights.appInsights.instrumentation_key}"
  storageConnectionString = "${azurerm_storage_account.storageAccount.primary_blob_connection_string}"
  storageAccountId        = "${azurerm_storage_account.storageAccount.id}"
  logAnalyticsId          = "${azurerm_log_analytics_workspace.logAnalytics.id}"
  logAnalyticsName        = "${azurerm_log_analytics_workspace.logAnalytics.name}"
  vnetName                = "${azurerm_subnet.appSubnet.name}"
}

module "webSite" {
  namePrefix          = "${var.namePrefix}"
  location            = "${var.location}"
  resourceGroupName   = "${azurerm_resource_group.resourceGroup.name}"
  keyVaultUrl         = "${azurerm_key_vault.keyVault.vault_uri}"
  keyVaultAccountName = "${azurerm_key_vault.keyVault.name}"
  keyVaultId          = "${azurerm_key_vault.keyVault.id}"
  appInsightsKey      = "${azurerm_application_insights.appInsights.instrumentation_key}"
  storageAccountId    = "${azurerm_storage_account.storageAccount.id}"
  logAnalyticsId      = "${azurerm_log_analytics_workspace.logAnalytics.id}"
  logAnalyticsName    = "${azurerm_log_analytics_workspace.logAnalytics.name}"
  vnetName            = "${azurerm_subnet.appSubnet.name}"
  vnetId              = "${azurerm_subnet.appSubnet.id}"
  servicePrincipalObjectId = "${var.servicePrincipalObjectId}"
  servicePrincipalClientId = "${var.servicePrincipalClientId}"
  servicePrincipalSecretName = "${var.servicePrincipalSecretName}"
}

module "data" {
  namePrefix        = "${var.namePrefix}"
  location          = "${var.location}"
  resourceGroupName = "${azurerm_resource_group.resourceGroup.name}"
  vnetId            = "${azurerm_subnet.appSubnet.id}"
  storageAccountId  = "${azurerm_storage_account.storageAccount.id}"
  logAnalyticsId    = "${azurerm_log_analytics_workspace.logAnalytics.id}"
  logAnalyticsName  = "${azurerm_log_analytics_workspace.logAnalytics.name}"
  keyVaultId        = "${azurerm_key_vault.keyVault.id}"
  keyVaultPermId    = "${azurerm_key_vault_access_policy.deployKeyVaultPolicy.id}"
}

module "appGateway" {
  enabled           = "${var.appgateway}"
  source            = "./front-end-networking/appgateway"
  namePrefix        = "${var.namePrefix}"
  location          = "${var.location}"
  resourceGroupName = "${azurerm_resource_group.resourceGroup.name}"
  vnetName          = "${azurerm_virtual_network.virtualNetwork.name}"
  subnetId          = "${azurerm_subnet.networkingSubnet.id}"
  webSiteFQDN       = "${module.webSite.webSiteFQDN}"
  storageAccountId  = "${azurerm_storage_account.storageAccount.id}"
  logAnalyticsId    = "${azurerm_log_analytics_workspace.logAnalytics.id}"
  logAnalyticsName  = "${azurerm_log_analytics_workspace.logAnalytics.name}"
}

resource "azurerm_storage_share" "aciLogShare" {
  name = "dataloader-share"

  resource_group_name  = "${azurerm_resource_group.resourceGroup.name}"
  storage_account_name = "${azurerm_storage_account.storageAccount.name}"

  quota = 50
}

resource "azurerm_container_group" "dataLoaders" {
  name                = "aci-dataloader-${lower(var.namePrefix)}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.resourceGroup.name}"
  ip_address_type     = "public"
  dns_name_label      = "contosoTravel-dataLoader-${var.namePrefix}"
  os_type             = "Linux"
  restart_policy      = "OnFailure"

  container {
    name   = "dataloader-aci-logs"
    image  = "andywahr/arkhitekton-dataloader"
    cpu    = "0.5"
    memory = "1.5"

    ports = {
      port     = 80
      protocol = "TCP"
    }

    environment_variables {
      "NODE_ENV" = "${azurerm_key_vault.keyVault.vault_uri}"
    }

    volume {
      name       = "logs"
      mount_path = "/aci/logs"
      read_only  = false
      share_name = "${azurerm_storage_share.aciLogShare.name}"

      storage_account_name = "${azurerm_storage_account.storageAccount.name}"
      storage_account_key  = "${azurerm_storage_account.storageAccount.primary_access_key}"
    }
  }
}
