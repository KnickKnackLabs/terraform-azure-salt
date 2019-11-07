# ------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters
# ------------------------------------------------------------------------------

variable "location" {
  description = "The azure region that the resource will run in."
}

variable "environment" {
  description = "The enviroment that the resource will be provisioned in."
}

variable "resource_group_name" {
  description = "The name of the resource group that the resources will run in."
}

variable "instance_size" {
  description = "The size of Azure Instances to run for each node in the cluster (e.g. Standard_A0)."
}

variable "subscription_id" {
  description = "The ID of the subscription in which the resource will be created."
}

variable "subnet_id" {
  description = "The id of the subnet to deploy the cluster into."
}

variable "prefix" {
    description = "Prefix for the scaleset"
}

variable "cloud_init" {
    description = "Cloud init used to initialize the machine with"
}

# ------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# Parameters which you can override but have nice defaults
# ------------------------------------------------------------------------------

variable "initial_cluster_size" {
  description = "Initial Size of VMSS"
  default = "0"
}

variable "instance_tier" {
  description = "Specifies the tier of virtual machines in a scale set. Possible values, standard or basic."
  default     = "standard"
}

variable "single_placement_group" {
  description = "Specifies whether the scale set is limited to a single placement group with a maximum size of 100 virtual machines."
  default     = "true"
}

variable "ignore_change_state" {
  description = "Ignore the list of properties. Useful for autoscaling with [\"sku.0.capacity\"]"
  default = []
}