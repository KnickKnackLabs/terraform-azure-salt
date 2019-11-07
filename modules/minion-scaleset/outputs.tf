output "scale_set_name" {
  description = "The name of the Azure VMSS created"
  value       = "${var.prefix}"
}

output "initial_cluster_size" {
  value       = "${var.initial_cluster_size}"
  description = "Initial size of the cluster created."
}

