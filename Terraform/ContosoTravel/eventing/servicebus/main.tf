
variable "namePrefix" {
  type = "string"
}

variable "location" {
   type = "string"
}

variable "resourceGroupName" {
   type = "string"
}

resource "azurerm_servicebus_namespace" "serviceBus" {
  name                = "sb-${var.namePrefix}-contosotravel"
  location            = "${var.location}"
  resource_group_name = "${var.resourceGroupName}"   
  sku                 = "Standard"
}

resource "azurerm_servicebus_queue" "serviceBusQueue" {
  name                  = "PurchaseItinerary"
  resource_group_name = "${var.resourceGroupName}"   
  namespace_name        = "${azurerm_servicebus_namespace.serviceBus.name}"
  default_message_ttl   = "P1D"
  max_size_in_megabytes = "1024"

  enable_partitioning = false
}

resource "azurerm_servicebus_queue_authorization_rule" "serviceBusReaderRule" {
  name                = "PurchaseItinerary-Reader"
  namespace_name      = "${azurerm_servicebus_namespace.serviceBus.name}"
  queue_name          = "${azurerm_servicebus_queue.serviceBusQueue.name}"
  resource_group_name = "${var.resourceGroupName}"   

  listen = true
  send   = false
  manage = false
}

resource "azurerm_servicebus_queue_authorization_rule" "serviceBusWriterRule" {
  name                = "PurchaseItinerary-Writer"
  namespace_name      = "${azurerm_servicebus_namespace.serviceBus.name}"
  queue_name          = "${azurerm_servicebus_queue.serviceBusQueue.name}"
  resource_group_name = "${var.resourceGroupName}"   

  listen = false
  send   = true
  manage = false
}

output "serviceAccountName" {
  value = "${azurerm_servicebus_namespace.serviceBus.name}"
}

output "serviceConnectionString" {
  value = "${azurerm_servicebus_queue_authorization_rule.serviceBusReaderRule.primary_connection_string}"
}

output "eventingConnectionString" {
  value = "${azurerm_servicebus_queue_authorization_rule.serviceBusWriterRule.primary_connection_string}"
}