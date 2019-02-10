variable "namePrefix" {
  type = "string"
}

variable "location" {
   type = "string"
}

variable "resourceGroupName" {
   type = "string"
}

resource "azurerm_eventgrid_topic" "eventGrid" {
  name                = "eg-${var.namePrefix}-contosotravel"
  location            = "${var.location}"
  resource_group_name = "${var.resourceGroupName}"    
}

output "serviceAccountName" {
  value = "${azurerm_eventgrid_topic.eventGrid.name}"
}

output "serviceConnectionString" {
  value = ""
}

output "eventingConnectionString" {
  value = ""
}