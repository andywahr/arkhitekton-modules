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

variable "keyVaultUrl" {
  type = "string"
}

variable "keyVaultAccountName" {
  type = "string"
}

variable "keyVaultId" {
  type = "string"
}

variable "appInsightsKey" {
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

variable "platform" {
  type = "string"
}

module "aksInstall" {
  source = "../../Kubernetes"
  namePrefix = "${var.namePrefix}"
  location = "${var.location}"
  resourceGroupName = "${var.resourceGroupName}"
  keyVaultUrl = "${var.keyVaultUrl}"
  keyVaultAccountName = "${var.keyVaultAccountName}"
  keyVaultId = "${var.keyVaultId}"
  appInsightsKey = "${var.appInsightsKey}"
  storageAccountId = "${var.storageAccountId}" 
  logAnalyticsId = "${var.logAnalyticsId}"
  logAnalyticsName = "${var.logAnalyticsName}"
  vnetName = "${var.vnetName}"
  vnetId = "${var.vnetId}"
  servicePrincipalClientId = "${var.servicePrincipalClientId}"
  servicePrincipalObjectId = "${var.servicePrincipalObjectId}"
  servicePrincipalSecretName = "${var.servicePrincipalSecretName}"
  standalone = "true"
}

data "azurerm_kubernetes_cluster" "aksRef" {
  name                = "${module.aksInstall.aksName}"
  resource_group_name = "${var.resourceGroupName}"
}

resource "azurerm_key_vault_secret" "webSiteFQDN" {
  name         = "ContosoTravel--WebSiteFQDN"
  value        = "http://contosotravel-web.module.${data.azurerm_kubernetes_cluster.aksRef.addon_profile.0.http_application_routing.0.http_application_routing_zone_name}"
  key_vault_id = "${var.keyVaultId}"
}

output "webSiteFQDN" {
  value = "contosotravel-web.${data.azurerm_kubernetes_cluster.aksRef.addon_profile.0.http_application_routing.0.http_application_routing_zone_name}"
}
