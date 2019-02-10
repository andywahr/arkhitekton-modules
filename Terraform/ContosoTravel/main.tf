variable "namePrefix" {
  type = "string"
}

variable "location" {
    type ="string"
}

locals {
  resourceGroupName = "rg-${var.namePrefix}"
}


data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "resourceGroup" {
  name     = "${local.resourceGroupName}"
  location = "${var.location}"
}

resource "azurerm_log_analytics_workspace" "logAnalytics" {
  name                = "${var.namePrefix}logAnalytics"
  resource_group_name = "${azurerm_resource_group.resourceGroup.name}"
  location            = "East US"
  sku                 = "pergb2018"
  retention_in_days   = 30
}

resource "azurerm_virtual_network" "virtualNetwork" {
  name                = "${var.namePrefix}vnet"
  location            = "${azurerm_resource_group.resourceGroup.location}"
  resource_group_name = "${azurerm_resource_group.resourceGroup.name}"
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet1" {
  name                 = "subnet1"
  resource_group_name  = "${azurerm_resource_group.resourceGroup.name}"
  virtual_network_name = "${azurerm_virtual_network.virtualNetwork.name}"
  address_prefix       = "10.0.0.0/24"
  service_endpoints    = ["Microsoft.AzureActiveDirectory", "Microsoft.AzureCosmosDB", "Microsoft.EventHub", "Microsoft.KeyVault", "Microsoft.ServiceBus", "Microsoft.Sql", "Microsoft.Storage"]

  delegation {
    name = "acctestdelegation"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "subnet2" {
  name                 = "subnet2"
  resource_group_name  = "${azurerm_resource_group.resourceGroup.name}"
  virtual_network_name = "${azurerm_virtual_network.virtualNetwork.name}"
  address_prefix       = "10.0.1.0/24"
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

  network_rules {
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = ["${azurerm_subnet.subnet1.id}", "${azurerm_subnet.subnet2.id}"]
  }
}

resource "azurerm_application_insights" "appInsights" {
  name                = "${var.namePrefix}appInsightContosoTravel"
  location            = "${azurerm_resource_group.resourceGroup.location}"
  resource_group_name = "${azurerm_resource_group.resourceGroup.name}"
  application_type    = "Web"
}

resource "azurerm_key_vault" "keyVault" {
  name                = "kv${var.namePrefix}"
  location            = "${azurerm_resource_group.resourceGroup.location}"
  resource_group_name = "${azurerm_resource_group.resourceGroup.name}"
  tenant_id           = "${data.azurerm_client_config.current.tenant_id}"

  sku {
    name = "standard"
  }
}

module "eventing" {
  source = "./eventing/eventGrid"
  namePrefix   = "${var.namePrefix}"
  location = "${var.location}"
  resourceGroupName = "${local.resourceGroupName}"
} 

module "service" {
  source = "./backend/functions"
  namePrefix   = "${var.namePrefix}"
  location = "${var.location}"
  resourceGroupName = "${local.resourceGroupName}"
  serviceConnectionString = "${module.eventing.serviceConnectionString}"
  keyVaultUrl = "${azurerm_key_vault.keyVault.vault_uri}"
  keyVaultAccountName = "${azurerm_key_vault.keyVault.name}"
  appInsightsKey = "${azurerm_application_insights.appInsights.instrumentation_key}"
  storageConnectionString = "${azurerm_storage_account.storageAccount.primary_blob_connection_string}"
} 

module "webSite" {
  source = "./web/appservice"
  namePrefix   = "${var.namePrefix}"
  location = "${var.location}"
  resourceGroupName = "${local.resourceGroupName}"
  serviceConnectionString = "${module.eventing.serviceConnectionString}"
  keyVaultUrl = "${azurerm_key_vault.keyVault.vault_uri}"
  keyVaultAccountName = "${azurerm_key_vault.keyVault.name}"
  appInsightsKey = "${azurerm_application_insights.appInsights.instrumentation_key}"
} 