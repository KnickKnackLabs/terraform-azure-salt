terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.35.0"
    }
  }
}

locals {
  scripts_path = "${path.module}/../../scripts"
}

resource "azurerm_network_interface" "main" {
  count = var.minion_count

  name                = "${var.prefix}-${var.name}-${count.index + 1}-nic"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  ip_configuration {
    name                          = "${var.prefix}-${var.name}-${count.index + 1}-ip-configuration"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "dynamic"
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_network_interface_security_group_association" "main" {
  count                     = var.minion_count
  network_interface_id      = azurerm_network_interface.main[count.index].id
  network_security_group_id = var.network_security_group_id
}

resource "azurerm_network_interface_application_security_group_association" "main" {
  count                         = var.minion_count
  network_interface_id          = azurerm_network_interface.main[count.index].id
  application_security_group_id = var.application_security_group_id
}

resource "azurerm_network_interface_backend_address_pool_association" "main" {
  for_each = {
    for i, v
    in setproduct(var.lb_backend_address_pool_ids, range(var.minion_count))
    : i => {
      lb_backend_address_pool_id = v[0],
      minion_idx                 = v[1],
    }
  }

  network_interface_id    = azurerm_network_interface.main[each.value.minion_idx].id
  ip_configuration_name   = "${var.prefix}-${var.name}-${each.value.minion_idx + 1}-ip-configuration"
  backend_address_pool_id = each.value.lb_backend_address_pool_id
}

resource "azurerm_linux_virtual_machine" "main" {
  count = var.minion_count

  name                = "${var.prefix}-${var.name}-${count.index + 1}-vm"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.instance_size
  tags                = var.tags

  network_interface_ids = [azurerm_network_interface.main[count.index].id]

  admin_username = var.auth["user"]
  admin_ssh_key {
    username   = var.auth["user"]
    public_key = var.auth["public_key"]
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name                 = "${var.prefix}-${var.name}-${count.index + 1}-osdisk"
    disk_size_gb         = var.disk_size_gb
    storage_account_type = var.storage_account_type
    caching              = "ReadWrite"
  }

  connection {
    host        = azurerm_network_interface.main[count.index].private_ip_address
    user        = var.auth["user"]
    private_key = var.auth["private_key"]
    timeout     = "1m"
  }

  provisioner "remote-exec" {
    script = "${local.scripts_path}/wait_cloud_init.sh"
  }

  provisioner "file" {
    source      = "${local.scripts_path}/install_salt.sh"
    destination = "/tmp/install_salt.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/install_salt.sh",
      "SALT_VERSION=${var.salt_version} sudo -E /tmp/install_salt.sh minion",
    ]
  }

  provisioner "file" {
    content     = jsonencode(var.grains)
    destination = "/tmp/grains"
  }

  provisioner "file" {
    content = templatefile("${path.module}/files/minion.tmpl", {
      minion_id      = "${var.prefix}-${var.name}-${count.index + 1}"
      master_address = var.salt_master_address
    })
    destination = "/tmp/minion"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/grains /etc/salt/grains",
      "sudo mv /tmp/minion /etc/salt/minion",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo service salt-minion restart",
    ]
  }

  lifecycle {
    ignore_changes = [tags]
  }
}
