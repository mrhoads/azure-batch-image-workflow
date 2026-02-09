packer {
  required_plugins {
    azure = {
      version = ">= 2.0.0"
      source  = "github.com/hashicorp/azure"
    }
  }
}

# Variable definitions
variable "client_id" {
  type    = string
  default = env("ARM_CLIENT_ID")
}

variable "client_secret" {
  type      = string
  default   = env("ARM_CLIENT_SECRET")
  sensitive = true
}

variable "subscription_id" {
  type    = string
  default = env("ARM_SUBSCRIPTION_ID")
}

variable "tenant_id" {
  type    = string
  default = env("ARM_TENANT_ID")
}

variable "resource_group" {
  type    = string
  default = "demo-batch-rg"
}

variable "location" {
  type    = string
  default = "canadacentral"
}

variable "image_name" {
  type    = string
  default = "ubuntu-2404-batch"
}

variable "image_version" {
  type    = string
  default = "1.0.0"
}

variable "gallery_name" {
  type    = string
  default = "demo_batch_gallery"
}

variable "gallery_image_name" {
  type    = string
  default = "custom-ubu2404"
}

variable "gallery_image_version" {
  type    = string
  default = "1.0.0"
}

variable "vm_size" {
  type    = string
  default = "Standard_D2s_v3"
}

# Source block for Azure ARM
source "azure-arm" "ubuntu" {
  # Authentication
  client_id       = var.client_id
  client_secret   = var.client_secret
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id

  # Resource configuration
  # Note: When using Secure Boot/vTPM, must publish directly to Shared Image Gallery
  # managed_image_name is not compatible with secure_boot_enabled/vtpm_enabled
  build_resource_group_name = var.resource_group
  vm_size                   = var.vm_size

  # OS Image configuration - Ubuntu 24.04 LTS
  os_type         = "Linux"
  image_publisher = "Canonical"
  image_offer     = "ubuntu-24_04-lts"
  image_sku       = "server"
  image_version   = "latest"

  # Generation 2 / Secure Launch configuration
  secure_boot_enabled = true
  vtpm_enabled        = true
  os_disk_size_gb     = 30

  # Azure Compute Gallery configuration
  # Publishing directly to gallery is required for Secure Boot/vTPM
  shared_image_gallery_destination {
    subscription         = var.subscription_id
    resource_group       = var.resource_group
    gallery_name         = var.gallery_name
    image_name           = var.gallery_image_name
    image_version        = var.gallery_image_version
    replication_regions  = [var.location]
    storage_account_type = "Standard_LRS"
  }

  # Additional settings
  azure_tags = {
    Environment = "Production"
    Purpose     = "Azure Batch"
    OS          = "Ubuntu 24.04"
    ImageType   = "Custom"
    Tools       = "stress,fio"
  }
}

# Build configuration
build {
  name    = "ubuntu-batch-image"
  sources = ["source.azure-arm.ubuntu"]

  # Update system packages
  provisioner "shell" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait",
      "echo 'Updating package lists...'",
      "sudo apt-get update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y",
    ]
  }

  # Install required applications
  provisioner "shell" {
    script = "${path.root}/scripts/install-apps.sh"
  }

  # Run system hardening
  provisioner "shell" {
    script = "${path.root}/scripts/harden-system.sh"
  }

  # Install and run Trivy vulnerability scanner
  provisioner "shell" {
    script = "${path.root}/scripts/scan-vulnerabilities.sh"
  }

  # Clean up before image capture
  provisioner "shell" {
    script = "${path.root}/scripts/cleanup.sh"
  }

  # Generalize the image (Azure requirement)
  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
    inline = [
      "/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync"
    ]
    inline_shebang = "/bin/sh -x"
  }

  # Post-processor to create manifest file
  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}
