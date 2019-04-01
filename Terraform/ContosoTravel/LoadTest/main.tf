variable "namePrefix" {
  type = "string"
}

variable "resourceGroupName" {
  type = "string"
}

data "azurerm_resource_group" "resourceGroup" {
  name = "${var.resourceGroupName}"
}

data "azurerm_key_vault" "keyVault" {
  name                = "kv${var.namePrefix}"
  resource_group_name = "${data.azurerm_resource_group.resourceGroup.name}"
}

data "azurerm_key_vault_secret" "webSiteFQDN" {
  name         = "ContosoTravel--WebSiteFQDN"
  key_vault_id = "${data.azurerm_key_vault.keyVault.id}"
}

resource "azurerm_container_group" "loadTestEastUS2" {
  name                = "aci-loadtest-eastus2-${lower(var.namePrefix)}"
  location            = "eastus2"
  resource_group_name = "${data.azurerm_resource_group.resourceGroup.name}"
  ip_address_type     = "public"
  dns_name_label      = "contosoTravel-loadtest-eastus2-${var.namePrefix}"
  os_type             = "Linux"
  restart_policy      = "OnFailure"

  container {
    name   = "loadtest"
    image  = "andywahr/arkhitekton-loadtest"
    cpu    = "2"
    memory = "3.5"

    ports = {
      port     = 80
      protocol = "TCP"
    }

    environment_variables {
      "URL" = "${replace(data.azurerm_key_vault_secret.webSiteFQDN.value, "//$/", "")}"
    }
  }
}

resource "azurerm_container_group" "loadTestWestUS2" {
  name                = "aci-loadtest-westus2-${lower(var.namePrefix)}"
  location            = "westus2"
  resource_group_name = "${data.azurerm_resource_group.resourceGroup.name}"
  ip_address_type     = "public"
  dns_name_label      = "contosoTravel-loadtest-westus2-${var.namePrefix}"
  os_type             = "Linux"
  restart_policy      = "OnFailure"

  container {
    name   = "loadtest"
    image  = "andywahr/arkhitekton-loadtest"
    cpu    = "2"
    memory = "3.5"

    ports = {
      port     = 80
      protocol = "TCP"
    }

    environment_variables {
      "URL" = "${replace(data.azurerm_key_vault_secret.webSiteFQDN.value, "//$/", "")}"
    }
  }
}

resource "azurerm_container_group" "loadTestNorthCentralUS" {
  name                = "aci-loadtest-northcentralus-${lower(var.namePrefix)}"
  location            = "northcentralus"
  resource_group_name = "${data.azurerm_resource_group.resourceGroup.name}"
  ip_address_type     = "public"
  dns_name_label      = "contosoTravel-loadtest-northcentralus-${var.namePrefix}"
  os_type             = "Linux"
  restart_policy      = "OnFailure"

  container {
    name   = "loadtest"
    image  = "andywahr/arkhitekton-loadtest"
    cpu    = "2"
    memory = "3.5"

    ports = {
      port     = 80
      protocol = "TCP"
    }

    environment_variables {
      "URL" = "${replace(data.azurerm_key_vault_secret.webSiteFQDN.value, "//$/", "")}"
    }
  }
}
