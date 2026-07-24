# --- Step 1: submit the Image Factory schematic -----------------------------
#
# Image Factory's /schematic endpoint is a content-addressed POST: the same
# schematic body always returns the same ID. Using a data source here means
# `terraform plan` will show no diff on repeat runs unless the schematic
# file actually changes.

data "http" "talos_schematic" {
  url          = "https://factory.talos.dev/schematics"
  method       = "POST"
  request_body = file("${path.module}/talos-schematic.yaml")

  request_headers = {
    Content-Type = "application/x-yaml"
  }
}

locals {
  schematic_id = jsondecode(data.http.talos_schematic.response_body).id
  image_url    = "https://factory.talos.dev/image/${local.schematic_id}/${var.talos_version}/nocloud-amd64.raw"
  image_name   = "talos-${var.talos_version}-${substr(local.schematic_id, 0, 8)}.raw"
}

# Step 2: download the built image directly into Proxmox storage 

resource "proxmox_download_file" "talos_image" {
  content_type = "import"
  datastore_id = var.iso_storage_pool
  node_name    = var.proxmox_node
  file_name    = local.image_name
  url          = local.image_url

  overwrite           = true
  overwrite_unmanaged  = true
  upload_timeout       = 900
}

# Step 3: seed VM, built from the downloaded image 

resource "proxmox_virtual_environment_vm" "talos_seed" {
  name      = "talos-seed-${var.talos_version}"
  node_name = var.proxmox_node
  vm_id     = var.seed_vm_id

  template = true
  machine  = "q35"

  cpu {
    cores   = var.seed_cores
    sockets = 1
    type    = "host"
  }

  memory {
    dedicated = var.seed_memory
    floating  = var.seed_memory
  }

  agent {
    enabled = true
  }

  network_device {
    bridge = var.bridge
    model  = "virtio"
  }

  disk {
    datastore_id = var.disk_storage_pool
    interface    = "scsi0"
    import_from  = proxmox_download_file.talos_image.id
    size         = var.disk_size_gb
  }

  scsi_hardware = "virtio-scsi-single"

  operating_system {
    type = "l26"
  }

  serial_device {
    device = "socket"
  }

  tags = ["talos-seed", "talos-seed-${var.talos_version}"]

  lifecycle {
    # The seed is a build artifact
    ignore_changes = [
      network_device,
    ]
  }
}

# --- Step 4: final, CAPMOX-facing tagged template ---------------------------

resource "proxmox_virtual_environment_vm" "talos_template" {
  name      = "talos-${var.talos_version}-template"
  node_name = var.proxmox_node
  vm_id     = var.template_vm_id

  template = true
  machine  = "q35"

  clone {
    vm_id = proxmox_virtual_environment_vm.talos_seed.vm_id
    full  = true
  }

  cpu {
    cores   = var.template_cores
    sockets = var.template_sockets
    type    = "host"
  }

  memory {
    dedicated = var.template_memory
    floating  = var.template_memory
  }

  agent {
    enabled = true
  }

  network_device {
    bridge = var.bridge
    model  = "virtio"
  }

  disk {
    datastore_id = var.disk_storage_pool
    interface    = "scsi0"
    size         = var.disk_size_gb
  }

  scsi_hardware = "virtio-scsi-single"

  tags = ["talos", "talos-${var.talos_version}"]

  depends_on = [proxmox_virtual_environment_vm.talos_seed]
}
