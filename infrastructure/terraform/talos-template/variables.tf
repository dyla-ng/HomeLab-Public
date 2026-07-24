variable "proxmox_endpoint" {
  type        = string
  description = "Proxmox API endpoint, e.g. https://REDACTED:8006/"
  default     = "https://REDACTED:8006/"
}

variable "proxmox_api_token" {
  type        = string
  description = "Proxmox API token, format: user@realm!tokenid=uuid"
  sensitive   = true
}

variable "proxmox_insecure_tls" {
  type        = bool
  description = "Skip TLS verification for self-signed Proxmox cert"
  default     = true
}

variable "proxmox_ssh_username" {
  type        = string
  description = "SSH username the provider uses for file upload operations"
  default     = "root"
}

variable "proxmox_node" {
  type        = string
  description = "Target Proxmox node name"
  default     = "R730PVE"
}

variable "iso_storage_pool" {
  type        = string
  description = "Proxmox storage pool for the downloaded raw image/ISO"
  default     = "local"
}

variable "disk_storage_pool" {
  type        = string
  description = "Proxmox storage pool for VM disks"
  default     = "Thinpool"
}

variable "bridge" {
  type        = string
  description = "Network bridge for the template's NIC"
  default     = "vmbr99"
}

variable "talos_version" {
  type        = string
  description = "Talos version to build"
  default     = "v1.13.5"
}

variable "seed_vm_id" {
  type        = number
  description = "VMID for the intermediate seed template (downloaded image, not yet CAPMOX-facing)"
  default     = 9000
}

variable "template_vm_id" {
  type        = number
  description = "VMID for the final, CAPMOX-facing tagged template"
  default     = 9110
}

variable "seed_cores" {
  type    = number
  default = 2
}

variable "seed_memory" {
  type    = number
  default = 2048
}

variable "template_cores" {
  type    = number
  default = 4
}

variable "template_sockets" {
  type    = number
  default = 1
}

variable "template_memory" {
  type    = number
  default = 4096
}

variable "disk_size_gb" {
  type        = number
  description = "Disk size in GB for both seed and final template"
  default     = 32
}
