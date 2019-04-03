# REQUIRED PARAMETERS

variable "subscription_id" {
  description = "The Azure subscription ID"
}

variable "resource_group_name" {
  description = "The name of the Azure resource group we will be deployed into. This RG should already exist"
}

variable "subnet_id" {
  description = "The ID of the Subnet under which the instance will be available"
}

variable "lb_backend_address_pool_id" {
  description = "A Load Balancer backend address pool ID to associate the minions with"
}

variable "salt_master_address" {
  description = "The address the minion can use to reach the salt master"
}

variable "auth" {
  description = "Credentials for accesing the machine"
  type        = "map"

  default = {
    user        = ""
    public_key  = ""
    private_key = ""
  }
}

# OPTIONAL PARAMETERS

variable "location" {
  description = "The Azure region the consul cluster will be deployed in"
  default     = "South Central US"
}

variable "instance_size" {
  description = "The instance size"
  default     = "Standard_F2"
}

variable "disk_size_gb" {
  description = "Specifies the size of the OS disk in GB."
  default     = 30
}

variable "network_security_group_id" {
  description = "The security group to put the network interfaces under"
  default     = ""
}

variable "application_security_group_ids" {
  description = "The application security groups to put the network interface under"
  default     = []
}

variable "prefix" {
  description = "A prefix for the instance and all of its associated resources"
  default     = "salt-minion"
}

variable "salt_version" {
  description = "The version of Salt to insatll"
  default     = "latest"
}

variable "name" {
  description = "A name for the minion"
  default     = "generic"
}

variable "num_of_minions" {
  description = "The number of minions to spawn"
  default     = 1
}

variable "tags" {
  type        = "map"
  default     = {}
  description = "Any tags which should be assigned to the resources"
}

variable "grains" {
  type        = "map"
  default     = {}
  description = "Grains to set on the minion"
}
