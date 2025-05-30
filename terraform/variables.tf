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
    core_fraction = 20
  }
}

data "yandex_compute_image" "ubuntu-lts" {
  family = "ubuntu-2204-lts"
}
