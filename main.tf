terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

variable "zone" {
  type        = string
  description = "Yandex.Cloud Zone"
  default     = "ru-central1-d"
}

variable "cloud_id" {
  type = string
}

variable "folder_id" {
  type        = string
  description = "Yandex.Cloud Folder ID"
}

variable "vm_user_login" {
  type = string
}

provider "yandex" {
  service_account_key_file = pathexpand("/Users/d.gorlov/yc-keys/key.json")
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}

resource "yandex_vpc_network" "network" {
  name = "vvot12-nextcloud-network"
}

resource "yandex_vpc_subnet" "subnet" {
  name       = "vvot12-nextcloud-subnet"
  zone       = var.zone
  v4_cidr_blocks = ["192.168.10.0/24"]
  network_id = yandex_vpc_network.network.id
}

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2404-lts-oslogin"
}

resource "yandex_compute_disk" "boot-disk" {
  name     = "vvot12-nextcloud-boot-disk"
  type     = "network-ssd"
  image_id = data.yandex_compute_image.ubuntu.id
  size     = 20
}

resource "yandex_compute_instance" "server" {
  name        = "vvot12-nextcloud-server"
  platform_id = "standard-v3"
  hostname    = "nextcloud"

  resources {
    core_fraction = 20
    cores         = 2
    memory        = 4
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot-disk.id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = "${var.vm_user_login}:${file("~/.ssh/id_rsa.pub")}"
  }
}

output "nextcloud-ip" {
  value = yandex_compute_instance.server.network_interface[0].nat_ip_address
}