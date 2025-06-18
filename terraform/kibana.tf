resource "yandex_compute_instance" "kibana" {
  name        = "kibana" 
  hostname    = "kibana" 
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
      memory        = 4
      cores         = var.vox.cores
      core_fraction = var.vox.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu-lts.image_id
      type     = "network-hdd"
      size     = 10
    }
  }

  metadata = {
    user-data          = file("./cloud-init-z.yml")
  }

  scheduling_policy { preemptible = false }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet-1.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.LAN.id, yandex_vpc_security_group.vox-mon.id]
  }
}

