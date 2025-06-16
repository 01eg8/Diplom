# Добавление прочих переменных
locals {
  db_name            = "vox_db"
  db_user            = "vox"
  db_password        = "123456789"
}

# Создание кластера БД PostgreSQL
resource "yandex_mdb_postgresql_cluster" "vox-pg-cluster" {
  name                = "vox-cluster"
  environment         = "PRODUCTION"
  network_id          = yandex_vpc_network.network-1.id
  security_group_ids  = [yandex_vpc_security_group.pgsql-sg.id]
  config {
    version = "17"
    resources {
      resource_preset_id = "b2.medium"
      disk_type_id       = "network-ssd"
      disk_size          = 10
    }
  }  
    host {
      zone      = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.subnet-1.id
    }
    host {
      zone      = "ru-central1-b"
      subnet_id = yandex_vpc_subnet.subnet-2.id
    }
  }

# Создание пользователя БД
resource "yandex_mdb_postgresql_user" "vox-user" {
  cluster_id = yandex_mdb_postgresql_cluster.vox-pg-cluster.id
  name       = local.db_user
  password   = local.db_password
}

# Создание БД
resource "yandex_mdb_postgresql_database" "vox-pg-tutorial-db" {
  cluster_id = yandex_mdb_postgresql_cluster.vox-pg-cluster.id
  name       = local.db_name
  owner      = local.db_user
}
