variable "proxmox_url" {
  type        = string
  description = "The Proxmox API URL (e.g., https://[IP REDACTED]:8006/api2/json)"
}

variable "proxmox_username" {
  type        = string
  description = "The Proxmox API token ID or username (e.g., [REDACTED]@pve!token-id)"
}

variable "proxmox_token" {
  type        = string
  description = "The Proxmox API token secret value"
  sensitive   = true
}

variable "proxmox_node" {
  type        = string
  description = "The Proxmox node name where the VM template will be built"
  default     = "pve"
}

variable "iso_file" {
  type        = string
  description = "The storage path to the AlmaLinux 9 minimal ISO (e.g., local:iso/AlmaLinux-9.4-x86_64-minimal.iso)"
}

variable "ssh_password" {
  type        = string
  description = "The SSH password for the temp build user (matching rootpw in ks.cfg)"
  default     = "almalinux"
  sensitive   = true
}
