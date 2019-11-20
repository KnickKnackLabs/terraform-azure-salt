/**
# Minion Cluster Scaleset

This module creates a Minion Scaleset. with an associated load balancer

## Usage:
module "qa-scus-optimization-workers-vmss" {
  source          = "git::https://gecgithub01.walmart.com/Torbit/terraform-azure-salt//modules/minion-scaleset"

  prefix = "qsoptw"
  environment         = "${var.environment}"
  location            = "${var.datacenter}"
  subscription_id     = "${var.subscription_id}"
  resource_group_name = "qa-scus-optimization-workers-vmss"

  subnet_id       = "${var.subnet_id}
}
**/
provider "azurerm" {
  subscription_id = "${var.subscription_id}"
}

resource "azurerm_resource_group" "minion_vmss_resource_group" {
  name     = "${var.resource_group_name}"
  location = "${var.location}"
}

resource "azurerm_virtual_machine_scale_set" "minion_scaleset" {
  name                = "${var.prefix}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.minion_vmss_resource_group.name}"

  upgrade_policy_mode    = "Manual"
  overprovision          = false
  single_placement_group = "${var.single_placement_group}"

  sku {
    name     = "${var.instance_size}"
    tier     = "${var.instance_tier}"
    capacity = "${var.initial_cluster_size}"
  }

  lifecycle {
    ignore_changes = ["sku[0].capacity"]
  }

  os_profile {
    computer_name_prefix = "${var.prefix}"
    custom_data          = "${var.cloud_init}"

    admin_username = "${var.admin_username}"
    admin_password = "${var.admin_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  network_profile {
    name    = "${var.prefix}-nic"
    primary = true

    ip_configuration {
      name      = "${var.prefix}-ipcfg"
      primary   = true
      subnet_id = "${var.subnet_id}"
    }
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
    os_type           = "Linux"
    managed_disk_type = "Standard_LRS"
    create_option     = "FromImage"
  }
}