packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.2"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox-iso" "almalinux" {
  # API Connection settings
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  token                    = var.proxmox_token
  node                     = var.proxmox_node
  insecure_skip_tls_verify = true

  # VM Spec settings
  vm_name                  = "almalinux-10.2-base-template"
  vm_id                    = 9100
  qemu_agent               = true
  cores                    = 2
  sockets                  = 1
  memory                   = 4096
  cpu_type                 = "host"
  boot                     = "order=scsi0;ide2"

  # Storage and media settings
  iso_file                 = var.iso_file
  unmount_iso              = true

  scsi_controller          = "virtio-scsi-pci"
  
  disks {
    type              = "scsi"
    storage_pool      = "Thinpool"  # Default LVM pool on Proxmox
    disk_size         = "32G"
    format            = "raw"
    discard           = true
  }

  network_adapters {
    model    = "virtio"
    bridge   = "vmbr99"
    vlan_tag = "115"
    firewall = false
  }

  # Autoinstall/Kickstart settings via secondary CD-ROM
  additional_iso_files {
    type             = "ide"
    index            = 3
    iso_storage_pool = "local"
    cd_files         = ["${path.root}/http/ks.cfg"]
    cd_label         = "cidata"
    unmount          = true
  }
  
  boot_command = [
    "<up><wait>",
    "e<wait>",
    "<down><down><end><wait>",
    " inst.text inst.ks=hd:sr1:/ks.cfg<wait>",
    "<f10>"
  ]
  boot_wait = "15s"

  # SSH access settings
  ssh_username             = "root"
  ssh_password             = var.ssh_password
  ssh_timeout              = "30m"
}

build {
  sources = ["source.proxmox-iso.almalinux"]

  # Step A: Install Kanidm server/client repository and utilities
  provisioner "shell" {
    inline = [
      "echo '> Enabling Kanidm Copr repository...'",
      "sudo dnf copr -y enable ligenix/enterprise-identity-management rhel+epel-10-x86_64",
      "echo '> Installing Kanidm server & client CLI...'",
      "sudo dnf install -y kanidm-server kanidm-clients",
      "echo '> Creating certs and data directory overrides...'",
      "getent group kanidm >/dev/null || sudo groupadd -r kanidm",
      "getent passwd kanidm >/dev/null || sudo useradd -r -g kanidm -d /var/lib/kanidm -s /sbin/nologin -c \"Kanidm Identity Management\" kanidm",
      "sudo mkdir -p /var/lib/kanidm/certs",
      "sudo chown -R kanidm:kanidm /var/lib/kanidm",
      "echo '> Configuring cloud-init datasource options...'",
      "sudo mkdir -p /etc/cloud/cloud.cfg.d",
      "echo 'datasource_list: [ NoCloud, ConfigDrive, OpenStack ]' | sudo tee /etc/cloud/cloud.cfg.d/90_dpkg.cfg"
    ]
  }

  # Step B: Clean up build traces to keep template minimal
  provisioner "shell" {
    inline = [
      "echo '> Disabling temporary root SSH password login...'",
      "sudo rm -f /etc/ssh/sshd_config.d/01-permitrootlogin.conf",
      "echo '> Cleaning up dnf cache and logs...'",
      "sudo dnf clean all",
      "sudo rm -rf /var/cache/dnf",
      "sudo rm -f /var/log/kickstart-post.log",
      "sudo rm -f /root/anaconda-ks.cfg",
      "echo '> Image preparation complete.'"
    ]
  }
}
