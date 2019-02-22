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

variable "my_principal_object_id" {
  type = "string"
  default = ""
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
  my_principal_object_id = "${var.my_principal_object_id}" 
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
