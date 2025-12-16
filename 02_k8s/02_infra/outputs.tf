#Пробная настройка вывода ip для дальнейшего использования в inventory.ini для kubespray
output "masters" {
  value = {
    for name, vm in yandex_compute_instance.k8s :
    name => {
      external_ip = vm.network_interface[0].nat_ip_address
      internal_ip = vm.network_interface[0].ip_address
    }
    if can(regex("master", name))
  }
}

output "workers" {
  value = {
    for name, vm in yandex_compute_instance.k8s :
    name => {
      external_ip = vm.network_interface[0].nat_ip_address
      internal_ip = vm.network_interface[0].ip_address
    }
    if can(regex("worker", name))
  }
}
