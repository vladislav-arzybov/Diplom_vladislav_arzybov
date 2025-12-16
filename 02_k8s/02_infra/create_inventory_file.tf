# Формируем inventory.ini для Ansible и Kubespray 
resource "local_file" "inventory_kubespray" {
  content = templatefile("${path.module}/inventory.tftpl", {
    masters = {
      for name, vm in yandex_compute_instance.k8s :
      name => {
        external_ip = vm.network_interface[0].nat_ip_address
        internal_ip = vm.network_interface[0].ip_address
      }
      if can(regex("master", name))
    }
    workers = {
      for name, vm in yandex_compute_instance.k8s :
      name => {
        external_ip = vm.network_interface[0].nat_ip_address
        internal_ip = vm.network_interface[0].ip_address
      }
      if can(regex("worker", name))
    }
  })
  filename = "ansible/inventory/inventory.ini"
}
