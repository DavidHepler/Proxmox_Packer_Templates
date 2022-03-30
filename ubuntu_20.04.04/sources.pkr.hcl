#############################################################
# Proxmox variables
#############################################################
variable "proxmox_hostname" {
  description = "Proxmox host address (e.g. https://192.168.1.1:8006)"
  type = string
}

variable "proxmox_username" {
  description = "Proxmox username (e.g. root@pam)"
  type = string
  default = "root@pam"
}

variable "proxmox_password" {
  description = "Proxmox password"
  type = string
  sensitive = true
}

variable "proxmox_node_name" {
  description = "Proxmox node"
  type = string
}

variable "proxmox_insecure_skip_tls_verify" {
  description = "Skip TLS verification?"
  type = bool
  default = true
}

#############################################################
# Template variables
#############################################################
variable "template_description" {
  description = "Template description"
  type = string
  default = "Ubuntu LTS 20.04.4 template (generated by Packer)"
}

variable "vm_id" {
  description = "VM template ID"
  type = number
}

variable "vm_name" {
  description = "VM name"
  type = string
  default = "Ubuntu-20.4.4-t"
}

variable "vm_storage_pool" {
  description = "Storage where template will be stored"
  type = string
}

variable "vm_cores" {
  description = "VM amount of memory"
  type = number
  default = 2
}

variable "vm_memory" {
  description = "VM amount of memory"
  type = number
  default = 4096
}

variable "vm_sockets" {
  description = "VM amount of CPU sockets"
  type = number
  default = 1
}

variable "iso_url" {
  description = "ISO image download link"
  type = string
  default = ""
}

variable "iso_storage_pool" {
  description = "Proxmox storage pool onto which to upload the ISO file."
  type = string
  default = "ISOs"
}
  
variable "iso_checksum" {
  description = " Checksum of the ISO file"
  type = string
  default = "28ccdb56450e643bad03bb7bcf7507ce3d8d90e8bf09e38f6bd9ac298a98eaad"
}

variable "iso_file" {
  description = "Location of ISO file on the server. E.g. local:iso/<filename>.iso"
  type = string
  default = "/mnt/pve/ISOs/template/iso/ubuntu-20.04.4-live-server-amd64.iso"
}

variable "pool" {
  description = " Name of resource pool to create virtual machine in"
  type = string
  default = "Templates"
}

#############################################################
# OS Settings
#############################################################
variable "username" {
  description = "Default username"
  type = string
}

variable "user_password" {
  description = "Default user password"
  type = string
  sensitive = true
}

variable "time_zone" {
  description = "Time Zone"
  type = string
  default = "Europe/Berlin"
}

#################BUILD#################
source "proxmox" "template" {
  proxmox_url               = "${var.proxmox_hostname}/api2/json"
  insecure_skip_tls_verify 	= var.proxmox_insecure_skip_tls_verify
  username                  = var.proxmox_username
  password                  = var.proxmox_password
  node                      = var.proxmox_node_name

  vm_name   = var.vm_name
  vm_id     = var.vm_id
  pool      = var.pool
  memory  	= var.vm_memory
  sockets   = var.vm_sockets
  cores     = var.vm_cores
  os        = "l26"

  network_adapters {
    model   = "virtio"
    bridge  = "vmbr172"
  }

  qemu_agent          = true
  scsi_controller     = "virtio-scsi-pci"

  disks {
    type              = "scsi"
    disk_size         = "100G"
    storage_pool      = var.vm_storage_pool
    storage_pool_type = "nfs"
    format            = "raw"
  }

  ssh_username          = var.username
  ssh_password          = var.user_password
  ssh_timeout           = "30m"

  iso_file              = var.iso_file
  iso_url               = var.iso_url
  iso_storage_pool      = var.iso_storage_pool
  iso_checksum          = var.iso_checksum

  onboot                  = true

  template_name           = var.vm_name
  template_description    = var.template_description
  unmount_iso             = true
  cloud_init              = true
  cloud_init_storage_pool = var.vm_storage_pool
  http_directory          = "./http"
  boot_wait               = "5s"
  boot_command            = [
        "<enter><enter><f6><esc><wait> ",
        "autoinstall ds=nocloud-net;seedfrom=http://{{ .HTTPIP }}:{{ .HTTPPort }}/",
        "<enter><wait>"
  ]
}

build {
  sources = [
    "source.proxmox.template"
  ]

  provisioner "shell" {
    pause_before = "90s"
    inline = [
      # Reset any existing cloud-init state
      "echo running cloud-init clean -s -l",
      "sudo rm -f /etc/cloud/cloud.cfg.d/99-installer.cfg",
      "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
      "sudo echo 'datasource_list: [ConfigDrive, NoCloud]' > 90_dpkg.cfg",
      "sudo apt-get update",
      "sudo apt-get -y upgrade",
      "sudo apt-get -y install qemu-guest-agent cloud-init",
      "sudo apt-get -y install nfs-common git vim htop",
      "sudo apt-get -y install wget curl",
      "sudo apt-get -y autoremove",
      "sudo apt-get -y clean",

    # Disable swap - generally recommended for K8s, but otherwise enable it for other workloads
    #"sudo swapoff -a",
    #"sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab",

      # DHCP Server assigns same IP address if machine-id is preserved, new machine-id will be generated on first boot
      "echo runningtruncate -s 0 /etc/machine-id",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo rm /var/lib/dbus/machine-id",
      "sudo ln -s /etc/machine-id /var/lib/dbus/machine-id",      
      "echo running cloud-init clean -s -l",

      "sudo cloud-init clean -s -l",
      "echo exiting....",
      "exit 0",
    ]
  }
}