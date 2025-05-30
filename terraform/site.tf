# Create a new Compute Instance Group

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

    scheduling_policy { preemptible = true }

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
