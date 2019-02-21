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

# Create Azure AD Application for Service Principal
resource "azuread_application" "aks" {
  name = "ContosoTravel-kub-${var.namePrefix}-sp"
}

# Create Service Principal
resource "azuread_service_principal" "aks" {
  application_id = "${azuread_application.aks.application_id}"
}

# Generate random string to be used for Service Principal Password
resource "random_string" "password" {
  length  = 32
  special = true
}

# Create Service Principal password
resource "azuread_service_principal_password" "aks" {
  end_date             = "2299-12-30T23:00:00Z"                # Forever
  service_principal_id = "${azuread_service_principal.aks.id}"
  value                = "${random_string.password.result}"
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
    client_id     = "${azuread_application.aks.application_id}"
    client_secret = "${azuread_service_principal_password.aks.value}"
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

provider "kubernetes" {
  host                   = "${azurerm_kubernetes_cluster.aks.kube_config.0.host}"
  username               = "${azurerm_kubernetes_cluster.aks.kube_config.0.username}"
  password               = "${azurerm_kubernetes_cluster.aks.kube_config.0.password}"
  client_certificate     = "${base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)}"
  client_key             = "${base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)}"
  cluster_ca_certificate = "${base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)}"
}

#resource "kubernetes_service_account" "tiller" {
#  metadata {
#    name      = "tiller"
#    namespace = "kube-system"
#  }
#}

#resource "kubernetes_cluster_role_binding" "tiller" {
#  metadata {
#    name = "tiller"
#  }

#  role_ref {
#    api_group = "rbac.authorization.k8s.io"
#    kind      = "ClusterRole"
#    name      = "cluster-admin"
#  }

#  subject {
#    api_group = ""
#    kind      = "ServiceAccount"
#    name      = "tiller"
#    namespace = "kube-system"
#  }
#}

# Initialize Helm (and install Tiller)
#provider "helm" {
#  install_tiller = true

#  kubernetes {
#    host                   = "${azurerm_kubernetes_cluster.aks.kube_config.0.host}"
#    username               = "${azurerm_kubernetes_cluster.aks.kube_config.0.username}"
#    password               = "${azurerm_kubernetes_cluster.aks.kube_config.0.password}"    
#    client_certificate     = "${base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)}"
#    client_key             = "${base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)}"
#    cluster_ca_certificate = "${base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)}"
#  }
#}

# Create Static Public IP Address to be used by Nginx Ingress
resource "azurerm_public_ip" "nginx_ingress" {
  name                = "aks-ContosoTravel-${var.namePrefix}-nginx-ingress-pip"
  location            = "${var.location}"
  resource_group_name = "${var.resourceGroupName}"
  allocation_method   = "Static"
  domain_name_label   = "www-aks-contosotravel-${lower(var.namePrefix)}"
}

# Add Kubernetes Stable Helm charts repo
#resource "helm_repository" "stable" {
#  name = "stable"
#  url  = "https://kubernetes-charts.storage.googleapis.com"
#}

# Install Nginx Ingress using Helm Chart
#resource "helm_release" "nginx_ingress" {
#  name       = "nginx-ingress"
#  repository = "${helm_repository.stable.metadata.0.name}"
#  chart      = "nginx-ingress"
#
#  set {
#    name  = "rbac.create"
#    value = "false"
#  }
#
#  set {
#    name  = "controller.service.externalTrafficPolicy"
#    value = "Local"
#  }
#
#  set {
#    name  = "controller.service.loadBalancerIP"
#    value = "${azurerm_public_ip.nginx_ingress.ip_address}"
#  }
#}

resource "azurerm_log_analytics_solution" "test" {
  solution_name         = "ContainerInsights"
  location              = "East US"
  resource_group_name   = "${var.resourceGroupName}"
  workspace_resource_id = "${var.logAnalyticsId}"
  workspace_name        = "${var.logAnalyticsName}"

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

output "webSiteFQDN" {
  value = "${azurerm_public_ip.nginx_ingress.fqdn}"
}
