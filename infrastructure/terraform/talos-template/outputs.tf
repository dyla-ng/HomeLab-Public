output "schematic_id" {
  description = "Talos Image Factory schematic ID used to build this image (pin/record for reproducibility)"
  value       = local.schematic_id
}

output "seed_vm_id" {
  description = "VMID of the intermediate seed template"
  value       = proxmox_virtual_environment_vm.talos_seed.vm_id
}

output "template_vm_id" {
  description = "VMID of the final, CAPMOX-facing tagged template"
  value       = proxmox_virtual_environment_vm.talos_template.vm_id
}

output "template_tags" {
  description = "Tags applied to the final template (should match ProxmoxMachine templateSelector.matchTags)"
  value       = proxmox_virtual_environment_vm.talos_template.tags
}
