resource "proxmox_virtual_environment_file" "user_data" {
  node_name    = var.target_node
  content_type = "snippets"
  datastore_id = "local"

  source_raw {
    data = templatefile("${path.module}/templates/user-data.yaml.tftpl", {
      domain             = var.domain
      origin             = var.origin
      admin_password     = var.admin_password
      idm_admin_password = var.idm_admin_password
      ssh_public_key     = var.ssh_public_key
    })
    file_name = "kanidm-user-data.yaml"
  }

}

resource "proxmox_virtual_environment_vm" "kanidm" {
  name        = "kanidm"
  description = "Out-of-Band Master Identity Provider VM (Kanidm)"
  node_name   = var.target_node
  vm_id       = var.vm_id
  tags        = ["oob", "identity", "kanidm"]

  # This is so that I can't accidentally delete the VM (and consequently, my user directory)
  # Run a kanidm database backup before touching this machine!
  lifecycle {
    prevent_destroy = true
  }



  clone {
    vm_id        = 9100 # The ID of the Packer template
    datastore_id = var.vm_disk_datastore
  }

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 4096
  }

  agent {
    enabled = true
  }

  initialization {
    datastore_id = var.cloud_init_datastore
    ip_config {
      ipv4 {
        address = "10.100.10.15/24"
        gateway = "10.100.10.1"
      }
    }
    user_data_file_id = proxmox_virtual_environment_file.user_data.id
  }

  network_device {
    bridge  = "vmbr99"
    vlan_id = 110
  }
}
