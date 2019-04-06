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

variable "backend" {
  type = "string"
}

resource "azurerm_public_ip" "webPIP" {
  name                = "webPIP-${var.namePrefix}"
  location            = "${var.location}"
  resource_group_name = "${var.resourceGroupName}"
  allocation_method   = "Dynamic"
  domain_name_label   = "website-contosotravel-${lower(var.namePrefix)}"
}

resource "azurerm_lb" "vmss" {
  name                = "vmss-lb"
  location            = "${var.location}"
  resource_group_name = "${var.resourceGroupName}"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = "${azurerm_public_ip.webPIP.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "bpepool" {
  resource_group_name = "${var.resourceGroupName}"
  loadbalancer_id     = "${azurerm_lb.vmss.id}"
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_probe" "vmss" {
  resource_group_name = "${var.resourceGroupName}"
  loadbalancer_id     = "${azurerm_lb.vmss.id}"
  name                = "vmss-probe"
  port                = 80
}

resource "azurerm_lb_rule" "lbnatrule" {
  resource_group_name            = "${var.resourceGroupName}"
  loadbalancer_id                = "${azurerm_lb.vmss.id}"
  name                           = "http"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.bpepool.id}"
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id                       = "${azurerm_lb_probe.vmss.id}"
}

resource "azurerm_virtual_machine_scale_set" "vmss" {
  name                = "vmscaleset-contosotravel-${var.namePrefix}"
  location            = "${var.location}"
  resource_group_name = "${var.resourceGroupName}"
  upgrade_policy_mode = "Manual"

  sku {
    name     = "Standard_DS1_v2"
    tier     = "Standard"
    capacity = 2
  }

  storage_profile_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_profile_data_disk {
    lun           = 0
    caching       = "ReadWrite"
    create_option = "Empty"
    disk_size_gb  = 10
  }

  os_profile {
    computer_name_prefix = "contosotravel-${lower(var.namePrefix)}"
    admin_username       = "${var.admin_user}"
    admin_password       = "${var.admin_password}"
    custom_data          = "${file("web.conf")}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  network_profile {
    name    = "terraformnetworkprofile"
    primary = true

    ip_configuration {
      name                                   = "IPConfiguration"
      subnet_id                              = "${var.vnetId}"
      load_balancer_backend_address_pool_ids = ["${azurerm_lb_backend_address_pool.bpepool.id}"]
      primary                                = true
    }
  }
}

output "webSiteFQDN" {
  value = "${azurerm_public_ip.webPIP.fqdn}"
}
