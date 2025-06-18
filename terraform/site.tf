
# providers
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  service_account_key_file = file("~/.authorized_key.json")
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
}

# переменные
variable "cloud_id" {
  type    = string
}

variable "folder_id" {
  type    = string
}

variable "service_account_id" {
  type    = string
}

variable "vox" {
  type = map(number)
  default = {
    cores         = 2
    memory        = 2
    core_fraction = 100
  }
}

data "yandex_compute_image" "ubuntu-lts" {
  family = "ubuntu-2204-lts"
}


# site
resource "yandex_compute_instance_group" "vox-vm-group" {
  name               = "vox-vm-group"
  folder_id          = var.folder_id
  service_account_id = var.service_account_id
    instance_template {
    hostname = "vx-{instance.index}"
        platform_id = "standard-v3"
    resources {
      memory        = var.vox.memory
      cores         = var.vox.cores
      core_fraction = var.vox.core_fraction
    }

    scheduling_policy { preemptible = false }

    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = data.yandex_compute_image.ubuntu-lts.image_id
        type     = "network-hdd"
        size     = 10
      }
    }

    network_interface {
      network_id         = yandex_vpc_network.network-1.id
      subnet_ids         = [yandex_vpc_subnet.subnet-1.id, yandex_vpc_subnet.subnet-2.id, yandex_vpc_subnet.subnet-3.id]
      nat                = false
      security_group_ids = [yandex_vpc_security_group.vox-vm-sg.id, yandex_vpc_security_group.LAN.id]
    }

    metadata = {
      user-data = file("./cloud-init.yml")
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    zones = ["ru-central1-a", "ru-central1-b", "ru-central1-d"]
  }

  deploy_policy {
    #max_unavailable = 1
    #max_expansion   = 0
    max_unavailable = 2
    max_creating    = 2
    max_expansion   = 2
    max_deleting    = 2
  }

  application_load_balancer {
    target_group_name = "vox-tg"
  }
}



# snapshots
resource "yandex_compute_snapshot_schedule" "vox_snap1" {
  schedule_policy {
    expression = "0 0 ? * *"
  }

  retention_period = "168h"

  snapshot_spec {
    description = "retention-snapshot"
  }

  disk_ids = [


    "${yandex_compute_instance.bastion.boot_disk.0.disk_id}", 
    "${yandex_compute_instance.zabbix.boot_disk.0.disk_id}",
    "${yandex_compute_instance.kibana.boot_disk.0.disk_id}",
    "${yandex_compute_instance.elasticsearch.boot_disk.0.disk_id}" #, 
    ] 
}


# output
resource "local_file" "ansible_inventory" {
  content  = <<-EOT
    [all]
    web1 ansible_host=vx-1
    web2 ansible_host=vx-2
    web3 ansible_host=vx-3
    elasticsearch ansible_host=elasticsearch
    kibana ansible_host=kibana
    bastion ansible_host=bastion
    zabbix ansible_host=zabbix

    [zab_ag]
    web1 ansible_host=vx-1
    web2 ansible_host=vx-2
    web3 ansible_host=vx-3
    elasticsearch ansible_host=elasticsearch
    kibana ansible_host=kibana
    bastion ansible_host=bastion

    [web_servers]
    web1 ansible_host=vx-1
    web2 ansible_host=vx-2
    web3 ansible_host=vx-3

    [zabbix_server]
    zabbix ansible_host=zabbix

    [elastic_server]
    elasticsearch ansible_host=elasticsearch

    [kibana_server]
    kibana ansible_host=kibana

    [bastion_server]
    bastion ansible_host=bastion

    [all:vars]
    ansible_user=amd48
    ansible_ssh_key_file=/home/amd48/.ssh/id_ed25519.pub
    ansible_ssh_common_args='-o StrictHostKeyChecking=no -o ProxyCommand="ssh -p 22 -W %h:%p -q amd48@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address}"'
    
    
    # ssh -J amd48@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address} amd48@zabbix 
    # ssh -J amd48@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address} amd48@kibana
    # ssh -J amd48@${yandex_compute_instance.bastion.network_interface.0.nat_ip_address} amd48@elasticsearch

    EOT
  filename = "../dplm-ans/hosts.ini"
}
