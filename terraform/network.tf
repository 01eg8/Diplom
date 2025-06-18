#создаем облачную сеть
resource "yandex_vpc_network" "network-1" {
  name        = "network-vox"
  description = "network-1"
}

#создаем подсеть zone 1
resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet-vox-1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["10.1.0.0/16"]
  route_table_id = yandex_vpc_route_table.rt.id
}

#создаем подсеть zone 2
resource "yandex_vpc_subnet" "subnet-2" {
  name           = "subnet-vox-2"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["10.2.0.0/16"]
  route_table_id = yandex_vpc_route_table.rt.id
}

#создаем подсеть zone 3
resource "yandex_vpc_subnet" "subnet-3" {
  name           = "subnet-vox-3"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["10.3.0.0/16"]
  route_table_id = yandex_vpc_route_table.rt.id
}

#создаем NAT для выхода в интернет
resource "yandex_vpc_gateway" "nat_gateway" {
  name = "vox-gateway"
  shared_egress_gateway {}
}

#создаем сетевой маршрут для выхода в интернет через NAT
resource "yandex_vpc_route_table" "rt" {
  name       = "vox-route-table"
  network_id = yandex_vpc_network.network-1.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

# Создание групп безопасности
resource "yandex_vpc_security_group" "vox-sg" {
  name       = "vox-sg"
  network_id = yandex_vpc_network.network-1.id

  egress {
    protocol       = "ANY"
    description    = "any"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 1
    to_port        = 65535
  }

  ingress {
    protocol       = "TCP"
    description    = "ext-http"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "ext-https"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }

  ingress {
    protocol          = "TCP"
    description       = "healthchecks"
    predefined_target = "loadbalancer_healthchecks"
    port              = 30080
  }
}

resource "yandex_vpc_security_group" "vox-mon" {
  name       = "vox-mon"
  network_id = yandex_vpc_network.network-1.id

  egress {
    protocol       = "ANY"
    description    = "any"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 1
    to_port        = 65535
  }

  ingress {
    protocol       = "TCP"
    description    = "ext-http"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 8080
  }

  ingress {
    protocol       = "TCP"
    description    = "ext-https"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 5601
  }

}

resource "yandex_vpc_security_group" "vox-vm-sg" {
  name       = "vox-vm-sg"
  network_id = yandex_vpc_network.network-1.id

  ingress {
    protocol          = "TCP"
    description       = "balancer"
    security_group_id = yandex_vpc_security_group.vox-sg.id
    port              = 80
  }

  ingress {
    protocol       = "TCP"
    description    = "ssh"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }
}

resource "yandex_vpc_security_group" "LAN" {
  name       = "LAN-sg"
  network_id = yandex_vpc_network.network-1.id
  ingress {
    description    = "Allow 10.0.0.0/8"
    protocol       = "ANY"
    v4_cidr_blocks = ["10.0.0.0/8"]
    from_port      = 0
    to_port        = 65535
  }
  egress {
    description    = "Permit ANY"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

resource "yandex_vpc_security_group" "bastion" {
  name       = "bastion-sg"
  network_id = yandex_vpc_network.network-1.id
  ingress {
    description    = "Allow 0.0.0.0/0"
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }
  egress {
    description    = "Permit ANY"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

# Создание группы бэкендов
resource "yandex_alb_backend_group" "vox-bg" {
  name = "vox-bg"
  http_backend {
    name             = "backend-1"
    port             = 80
    target_group_ids = [yandex_compute_instance_group.vox-vm-group.application_load_balancer.0.target_group_id]
    healthcheck {
      timeout          = "10s"
      interval         = "2s"
      healthcheck_port = 80
      http_healthcheck {
        path = "/"
      }
    }
  }
}

# Создание HTTP-роутера и виртуального хоста
resource "yandex_alb_http_router" "vox-router" {
  name = "vox-router"
}

resource "yandex_alb_virtual_host" "vox-host" {
  name           = "vox-host"
  http_router_id = yandex_alb_http_router.vox-router.id
  route {
    name = "route-1"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.vox-bg.id
      }
    }
  }
}

# Создание L7-балансировщика
resource "yandex_alb_load_balancer" "vox-1" {
  name               = "vox-1"
  network_id         = yandex_vpc_network.network-1.id
  security_group_ids = [yandex_vpc_security_group.vox-sg.id]

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.subnet-1.id
    }

    location {
      zone_id   = "ru-central1-b"
      subnet_id = yandex_vpc_subnet.subnet-2.id
    }

    location {
      zone_id   = "ru-central1-d"
      subnet_id = yandex_vpc_subnet.subnet-3.id
    }
  }

  listener {
    name = "alb-listener"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.vox-router.id
      }
    }
  }
}
