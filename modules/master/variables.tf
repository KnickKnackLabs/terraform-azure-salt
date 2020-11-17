variable "resource_group_name" {
  description = "The name of the Azure resource group we will be deployed into. This RG should already exist"
  type        = string
}

variable "subnet_id" {
  description = "The ID of the Subnet under which the instance will be available"
  type        = string
}

variable "auth" {
  description = "Credentials for accesing the machine"
  type = object({
    user        = string
    public_key  = string
    private_key = string
  })
}

variable "location" {
  description = "The Azure region master will be deployed in"
  type        = string
}

variable "instance_size" {
  description = "The instance size"
  type        = string
  default     = "Standard_F2"
}

variable "disk_size_gb" {
  description = "Specifies the size of the OS disk in GB."
  type        = number
  default     = 30
}

variable "storage_account_type" {
  description = "Specifies the type of the OS disk"
  type        = string
  default     = "Standard_LRS"
}

variable "network_security_group_id" {
  description = "The security group to put the network interface under"
  type        = string
}

variable "application_security_group_id" {
  description = "The application security group to put the network interface under"
  type        = string
}

variable "prefix" {
  description = "A prefix for the instance and all of its associated resources"
  type        = string
  default     = "salt-master"
}

variable "salt_version" {
  description = "The version of Salt to insatll"
  type        = string
  default     = "latest"
}

variable "name" {
  description = "A name for the master"
  type        = string
  default     = "generic"
}

variable "tags" {
  description = "Any tags which should be assigned to the resources"
  type        = map(string)
  default     = {}
}

variable "grains" {
  description = "Grains to set on the minion"
  type        = any
  default     = {}
}
