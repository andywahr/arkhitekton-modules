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

variable "keyVaultPermId" {
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
}

# Create Static Public IP Address to be used by Nginx Ingress
resource "azurerm_public_ip" "nginx_ingress" {
  name                = "aks-ContosoTravel-${var.namePrefix}-nginx-ingress-pip"
  location            = "${var.location}"
  resource_group_name = "${var.resourceGroupName}"
  allocation_method   = "Static"
  domain_name_label   = "www-aks-contosotravel-${lower(var.namePrefix)}"
}

output "webSiteFQDN" {
  value = "${azurerm_public_ip.nginx_ingress.fqdn}"
}
