###network

resource "yandex_vpc_network" "prod-vpc" {
  name = var.vpc_name
}

resource "yandex_vpc_subnet" "subnet-a" {
  name           = var.subnet-a_name
  zone           = var.zone-a
  network_id     = yandex_vpc_network.prod-vpc.id
  v4_cidr_blocks = var.subnet-a_cidr

}
resource "yandex_vpc_subnet" "subnet-b" {
  name           = var.subnet-b_name
  zone           = var.zone-b
  network_id     = yandex_vpc_network.prod-vpc.id
  v4_cidr_blocks = var.subnet-b_cidr
}

resource "yandex_vpc_subnet" "subnet-d" {
  name           = var.subnet-d_name
  zone           = var.zone-d
  network_id     = yandex_vpc_network.prod-vpc.id
  v4_cidr_blocks = var.subnet-d_cidr
}
