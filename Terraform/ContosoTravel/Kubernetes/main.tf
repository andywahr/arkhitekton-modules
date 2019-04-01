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

variable "standalone" {
  type = "string"
}

provider "azurerm" {
  subscription_id = "bc73a756-864c-4429-8918-fe8f8eeee4a7"
  alias           = "msftno"
}

data "azurerm_key_vault" "arkKeyVault" {
  name                = "kv-arkhitekton"
  resource_group_name = "rgArchitektron"
  provider            = "azurerm.msftno"
}

data "azurerm_key_vault_secret" "spClientSecret" {
  name         = "${var.servicePrincipalSecretName}"
  key_vault_id = "${data.azurerm_key_vault.arkKeyVault.id}"
  provider     = "azurerm.msftno"
}

resource "azurerm_user_assigned_identity" "aksPodIdentity" {
  name                = "aks-ContosoTravel-${var.namePrefix}"
  location            = "${var.location}"
  resource_group_name = "${var.resourceGroupName}"

  name  = "aks-contosotrvl-${var.namePrefix}"
  count = "${var.standalone == "true" ? 1 : 0}"
}

resource "azurerm_role_assignment" "aksPodIdentityRoleAssignment" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resourceGroupName}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${azurerm_user_assigned_identity.aksPodIdentity.name}"
  role_definition_name = "Managed Identity Operator"
  principal_id         = "${var.servicePrincipalObjectId}"
  count                = "${var.standalone == "true" ? 1 : 0}"
}

# Create ACR
resource "azurerm_container_registry" "acr" {
  name                = "acrContosoTravel${var.namePrefix}"
  location            = "${var.location}"
  resource_group_name = "${var.resourceGroupName}"
  admin_enabled       = false
  sku                 = "Standard"
  count               = "${var.standalone == "true" ? 1 : 0}"
}

resource "azurerm_role_assignment" "aksACRRoleAssignmentRead" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/${azurerm_container_registry.acr.name}"
  role_definition_name = "AcrPull"
  principal_id         = "${var.servicePrincipalObjectId}"
  count                = "${var.standalone == "true" ? 1 : 0}"
}

resource "azurerm_role_assignment" "aksACRRoleAssignmentWrite" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resourceGroupName}/providers/Microsoft.ContainerRegistry/registries/${azurerm_container_registry.acr.name}"
  role_definition_name = "AcrPush"
  principal_id         = "${data.azurerm_client_config.current.service_principal_object_id}"
  count             = "${var.standalone == "true" ? 1 : 0}"
}

# Create managed Kubernetes cluster (AKS)
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-ContosoTravel-${var.namePrefix}"
  location            = "${var.location}"
  resource_group_name = "${var.resourceGroupName}"
  dns_prefix          = "aks-ContosoTravel-${var.namePrefix}"

  agent_pool_profile {
    name            = "linuxpool"
    count           = 2
    vm_size         = "Standard_DS2_v2"
    os_type         = "Linux"
    os_disk_size_gb = 30
    vnet_subnet_id  = "${var.vnetId}"
  }

  service_principal {
    client_id     = "${var.servicePrincipalClientId}"
    client_secret = "${data.azurerm_key_vault_secret.spClientSecret.value}"
  }

  addon_profile {
    oms_agent {
      enabled                    = "true"
      log_analytics_workspace_id = "${var.logAnalyticsId}"
    }

    http_application_routing {
      enabled = true
    }
  }

  network_profile {
    network_plugin = "azure"
  }
  count             = "${var.standalone == "true" ? 1 : 0}"
}

resource "azurerm_log_analytics_solution" "ContainerInsights" {
  solution_name         = "ContainerInsights"
  location              = "East US"
  resource_group_name   = "${var.resourceGroupName}"
  workspace_resource_id = "${var.logAnalyticsId}"
  workspace_name        = "${var.logAnalyticsName}"

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
  count             = "${var.standalone == "true" ? 1 : 0}"
}

resource "azurerm_key_vault_access_policy" "kubKeyVaultPolicy" {
  key_vault_id = "${var.keyVaultId}"

  tenant_id = "${data.azurerm_client_config.current.tenant_id}"
  object_id = "${azurerm_user_assigned_identity.aksPodIdentity.principal_id}"

  secret_permissions = [
    "get",
    "list",
  ]
  count             = "${var.standalone == "true" ? 1 : 0}"
}

output "DNSZone" {
  value = "${azurerm_kubernetes_cluster.aks.http_application_routing.http_application_routing_zone_name}"
}