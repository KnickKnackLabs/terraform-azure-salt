provider "azurerm" {
  subscription_id = "${var.subscription_id}"
}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-${var.name}-nic"
  resource_group_name = "${var.resource_group_name}"
  location            = "${var.location}"
  tags                = "${var.tags}"

  ip_configuration {
    name                          = "${var.prefix}-${var.name}-ip-configuration"
    subnet_id                     = "${var.subnet_id}"
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}-${var.name}-vm"
  resource_group_name   = "${var.resource_group_name}"
  location              = "${var.location}"
  vm_size               = "${var.instance_size}"
  network_interface_ids = ["${azurerm_network_interface.main.id}"]

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.prefix}-${var.name}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.prefix}-${var.name}"
    admin_username = "${var.auth["user"]}"
    admin_password = "disabled"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.auth["user"]}/.ssh/authorized_keys"
      key_data = "${var.auth["public_key"]}"
    }
  }

  connection {
    user        = "${var.auth["user"]}"
    private_key = "${var.auth["private_key"]}"
    timeout     = "1m"
  }

  provisioner "remote-exec" {
    script = "${path.module}/../../scripts/setup_walmart.sh"
  }

  provisioner "file" {
    source      = "${path.module}/../../scripts/install_salt.sh"
    destination = "/tmp/install_salt.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/install_salt.sh",
      "SALT_VERSION=${var.salt_version} sudo -E /tmp/install_salt.sh master",
    ]
  }

  tags = "${var.tags}"
}
