provider "azurerm" {
  subscription_id = "${var.subscription_id}"
}

resource "azurerm_network_interface" "main" {
  count = "${var.num_of_minions}"

  name                = "${var.prefix}-${var.name}-${count.index + 1}-nic"
  resource_group_name = "${var.resource_group_name}"
  location            = "${var.location}"
  tags                = "${var.tags}"

  network_security_group_id = "${var.network_security_group_id}"

  ip_configuration {
    name                          = "${var.prefix}-${var.name}-${count.index + 1}-ip-configuration"
    subnet_id                     = "${var.subnet_id}"
    private_ip_address_allocation = "dynamic"

    application_security_group_ids = ["${var.application_security_group_ids}"]
  }
}

resource "azurerm_availability_set" "main" {
  count               = "${var.availability_set ? 1 : 0}"
  name                = "${var.prefix}-${var.name}-as"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  managed             = true
}

data "template_file" "minion_config" {
  count = "${var.num_of_minions}"

  template = "${file("${path.module}/files/minion.tpl")}"

  vars {
    minion_id      = "${var.prefix}-${var.name}-${count.index + 1}"
    master_address = "${var.salt_master_address}"
  }
}

resource "azurerm_managed_disk" "main" {
  count                = "${var.storage_data_disk["disk_size_gb"] > 0 ? var.num_of_minions : 0}"
  name                 = "${var.prefix}-${var.name}-${count.index + 1}-datadisk"
  disk_size_gb         = "${var.storage_data_disk["disk_size_gb"]}"
  location             = "${var.location}"
  resource_group_name  = "${var.resource_group_name}"
  storage_account_type = "${var.storage_data_disk["storage_account_type"]}"
  create_option        = "Empty"
}

resource "azurerm_virtual_machine_data_disk_attachment" "main" {
  count              = "${var.storage_data_disk["disk_size_gb"] > 0 ? var.num_of_minions : 0}"
  managed_disk_id    = "${azurerm_managed_disk.main.*.id[count.index]}"
  virtual_machine_id = "${azurerm_virtual_machine.main.*.id[count.index]}"
  lun                = "${var.storage_data_disk["lun"]}"
  caching            = "${var.storage_data_disk["caching"]}"
}

resource "azurerm_virtual_machine" "main" {
  count = "${var.num_of_minions}"

  name                  = "${var.prefix}-${var.name}-${count.index + 1}-vm"
  resource_group_name   = "${var.resource_group_name}"
  availability_set_id   = "${var.availability_set ? join("", azurerm_availability_set.main.*.id) : ""}"
  location              = "${var.location}"
  vm_size               = "${var.instance_size}"
  network_interface_ids = ["${azurerm_network_interface.main.*.id[count.index]}"]

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.prefix}-${var.name}-${count.index + 1}-osdisk"
    disk_size_gb      = "${var.disk_size_gb}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "${var.managed_disk_type}"
  }

  os_profile {
    computer_name  = "${var.prefix}-${var.name}-${count.index + 1}"
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
    script = "${path.module}/../../scripts/wait_cloud_init.sh"
  }

  provisioner "file" {
    source      = "${path.module}/../../scripts/setup_walmart_apt_repos.sh"
    destination = "/tmp/setup_walmart_apt_repos.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/setup_walmart_apt_repos.sh",
      "sudo /tmp/setup_walmart_apt_repos.sh",
    ]
  }

  provisioner "file" {
    source      = "${path.module}/../../scripts/install_salt.sh"
    destination = "/tmp/install_salt.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/install_salt.sh",
      "SALT_VERSION=${var.salt_version} sudo -E /tmp/install_salt.sh minion",
    ]
  }

  provisioner "file" {
    content     = "${jsonencode(var.grains)}"
    destination = "/tmp/grains"
  }

  provisioner "file" {
    content     = "${data.template_file.minion_config.*.rendered[count.index]}"
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

  tags = "${var.tags}"
}
