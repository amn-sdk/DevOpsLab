packer {
  required_plugins {
    virtualbox = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/virtualbox"
    }
  }
}

# --- Source : VirtualBox ARM ---
source "virtualbox-iso" "local_vm" {
  vm_name          = "sample-app-vbox-arm"
  iso_url          = "https://cdimage.ubuntu.com/releases/22.04/release/ubuntu-22.04.5-live-server-arm64.iso"
  iso_checksum     = "sha256:edbb93717f6b46b72646b4ff04e7987bde24acde6debe732267e5e01ef4318a1"
  ssh_username     = "packer"
  ssh_password     = "packer"
  ssh_timeout      = "30m"
  shutdown_command = "echo 'packer' | sudo -S shutdown -P now"
  guest_os_type    = "Ubuntu_64"

  disk_size   = 10000
  memory      = 1024
  cpus        = 1
}

build {
  sources = ["source.virtualbox-iso.local_vm"]

  provisioner "file" {
    source      = "app.js"
    destination = "/home/packer/app.js"
  }

  provisioner "shell" {
    inline = [
      "sudo apt-get update -y",
      "curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -",
      "sudo apt-get install -y nodejs",
      "nohup node /home/packer/app.js &"
    ]
  }
}
