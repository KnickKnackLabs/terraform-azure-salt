# minion-cluster-with-lb-association

This Terraform module is identical to the `minion-cluster` module with just the following two changes:

1. Add a _required_ `lb_backend_address_pool_id` variable to indicate a load balancer backend pool to associate the minions with.

```bash
variable "lb_backend_address_pool_id" {
  description = "A Load Balancer backend address pool ID to associate the minions with"
}
```

2. Add a `azurerm_network_interface_backend_address_pool_association` resource to associate the minions with the specified load balancer backend pool.

```bash
resource "azurerm_network_interface_backend_address_pool_association" "main" {
  count = "${var.num_of_minions}"

  network_interface_id    = "${azurerm_network_interface.main.*.id[count.index]}"
  ip_configuration_name   = "${var.prefix}-${var.name}-${count.index + 1}-ip-configuration"
  backend_address_pool_id = "${var.lb_backend_address_pool_id}"
}
```

**Note**: Pre Terraform 0.12, it's very painful to create any kind of complex logic in Terraform state files. Perhaps if we migrate to Terrform 0.12 we can combine this module and `minion-cluster`.

## Example Usage

This example shows how to set up a load balancer and provide it's backend pool ID to a salt-minion cluster.

```bash
locals {
  my_project_lb = {
    frontend_ip_configuration_name = "my-project-lb-fe-ipc"
    private_ip_address             = "1.2.3.4"
  }
}

# Set up a Load Balancer
resource "azurerm_lb" "my_project" {
  resource_group_name = "${azurerm_resource_group.main.name}"
  name                = "my-project-lb"
  location            = "${var.location}"
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "${local.my_project_lb["frontend_ip_configuration_name"]}"
    subnet_id                     = "${data.azurerm_subnet.main.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${local.my_project_lb["private_ip_address"]}"
  }
}

# Set up a Backend Address Pool
resource "azurerm_lb_backend_address_pool" "my_project" {
  resource_group_name = "${azurerm_resource_group.main.name}"
  name                = "my-project-lb-backend-address-pool"
  loadbalancer_id     = "${azurerm_lb.my_project.id}"
}

# Set up a Probe
resource "azurerm_lb_probe" "my_project" {
  resource_group_name = "${azurerm_resource_group.main.name}"
  name                = "my-project-lb-probe"
  loadbalancer_id     = "${azurerm_lb.my_project.id}"

  protocol     = "Http"
  port         = 9090
  request_path = "/metrics"

  interval_in_seconds = 5
  number_of_probes    = 2
}

# Set up a forwarding rule
resource "azurerm_lb_rule" "my_project" {
  resource_group_name = "${azurerm_resource_group.main.name}"
  name                = "my-project-lb-rule"
  loadbalancer_id     = "${azurerm_lb.my_project.id}"

  frontend_ip_configuration_name = "${local.my_project_lb["frontend_ip_configuration_name"]}"

  protocol      = "Udp"
  frontend_port = 6380
  backend_port  = 6380

  backend_address_pool_id = "${azurerm_lb_backend_address_pool.my_project.id}"
  probe_id                = "${azurerm_lb_probe.my_project.id}"
}

# Create the salt-minion cluster and provide it with the load-balancer backend address pool
module "my_project_salt_minion_cluster" {
  source = "git::https://gecgithub01.walmart.com/Torbit/terraform-azure-salt//modules/minion-cluster-with-lb-association"

  subscription_id     = "${var.subscription_id}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  subnet_id           = "${data.azurerm_subnet.main.id}"
  instance_size       = "Standard_F2"

  lb_backend_address_pool_id = "${azurerm_lb_backend_address_pool.my_project.id}"

  auth                = "${local.auth}"
  salt_version        = "2018.3"
  name                = "my-project"
  num_of_minions      = 1
  salt_master_address = "4.3.2.1"

  grains = {
    environment = "${local.environment}"
    roles       = ["my-project"]
  }
}
```
