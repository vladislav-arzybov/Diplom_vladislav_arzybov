###Создание ВМ через цикл for_each

resource "yandex_compute_instance" "k8s" {
  for_each    = var.each_vm
  name        = each.value.name
  hostname    = each.value.hostname
  platform_id = var.platform_id
  zone        = each.value.zone
    resources {
    cores         = each.value.cpu
    memory        = each.value.ram
    core_fraction = each.value.fraction

  }
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.image_id
      size     = each.value.disk_volume
    }
  }
  scheduling_policy {
    preemptible = var.vm_scheduling_policy_preemptible
  }
  network_interface {
    subnet_id = local.subnets[each.value.subnet]
    nat       = "true"
        #Назначаем master-node статический ip
    nat_ip_address = startswith(each.key, "master-node") ? yandex_vpc_address.master_ip.external_ipv4_address[0].address : null
  }

  metadata = {
    serial-port-enable = var.serial-port
    #ssh-keys           = "${var.user}:${local.ssh-key}" #Подключение через ssh key
    user-data          = data.template_file.cloudinit.rendered #Подключение через cloud-config
  }

}
