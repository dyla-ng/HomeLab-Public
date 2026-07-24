output "vm_id" {
  value       = proxmox_virtual_environment_vm.kanidm.vm_id
  description = "The Proxmox VM ID of the provisioned Kanidm server"
}

output "vm_name" {
  value       = proxmox_virtual_environment_vm.kanidm.name
  description = "The virtual machine name"
}

output "ipv4_addresses" {
  value       = proxmox_virtual_environment_vm.kanidm.ipv4_addresses
  description = "The IP addresses resolved from the QEMU Guest Agent"
}
