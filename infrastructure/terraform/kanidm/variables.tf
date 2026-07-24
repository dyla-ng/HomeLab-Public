variable "proxmox_api_endpoint" {
  type        = string
  description = "The Proxmox API Endpoint (e.g., https://REDACTED:8006/)"
}

variable "proxmox_api_token" {
  type        = string
  description = "The Proxmox API Token ID and secret (e.g., USER@pam!TOKEN_ID=SECRET)"
  sensitive   = true
}

variable "admin_password" {
  type        = string
  description = "The password for the global Kanidm admin account"
  sensitive   = true
}

variable "idm_admin_password" {
  type        = string
  description = "The password for the Kanidm idm_admin account"
  sensitive   = true
}

variable "domain" {
  type        = string
  description = "The FQDN of the Kanidm server"
  default     = "kanidm.lab.example.com"
}

variable "origin" {
  type        = string
  description = "The external Origin URL of the Kanidm server"
  default     = "https://kanidm.lab.example.com:8443"
}

variable "vm_id" {
  type        = number
  description = "The VM ID to assign to the Kanidm VM on Proxmox"
  default     = 995
}

variable "target_node" {
  type        = string
  description = "The Proxmox target node name"
  default     = "R730PVE"
}

variable "vm_disk_datastore" {
  type        = string
  description = "The target Proxmox datastore for the cloned VM disk"
  default     = "Thinpool"
}

variable "cloud_init_datastore" {
  type        = string
  description = "The target Proxmox datastore for the Cloud-init image"
  default     = "Thinpool"
}

variable "ssh_public_key" {
  type        = string
  description = "The SSH public key to authorize for the root user"
  sensitive   = true
}

