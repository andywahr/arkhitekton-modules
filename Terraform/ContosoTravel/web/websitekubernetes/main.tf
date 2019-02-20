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

resource "azurerm_kubernetes_cluster" "test" {
  name                = "${var.namePrefix}-kube"
  location            = "${var.location}"
  resource_group_name = "${var.resourceGroupName}"
  dns_prefix          = "${var.namePrefix}-kube"

  agent_pool_profile {
    name            = "default"
    count           = 2
    vm_size         = "Standard_D2_v3"
    os_type         = "Linux"
    os_disk_size_gb = 30
    vnet_subnet_id  = "${var.vnetId}"
  }

  service_principal {
    client_id     = "00000000-0000-0000-0000-000000000000"
    client_secret = "00000000000000000000000000000000"
  }

  addon_profile {
    oms_agent {
      enabled                    = "true"
      log_analytics_workspace_id = "${var.logAnalyticsId}"
    }

    http_application_routing {
      enabled = "true"
    }
  }

  network_profile {
    network_plugin = "azure"
  }
}

output "webSiteFQDN" {
  value = ""
}
