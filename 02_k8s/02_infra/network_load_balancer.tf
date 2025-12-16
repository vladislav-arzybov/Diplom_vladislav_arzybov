

# Создаем группу для балансировщика с включением всех нод
resource "yandex_lb_target_group" "k8s-nlb" {
  name       = "k8s-balancer-group"
  depends_on = [yandex_compute_instance.k8s]

  dynamic "target" {
    for_each = values(yandex_compute_instance.k8s)

    content {
      subnet_id = target.value.network_interface[0].subnet_id
      address   = target.value.network_interface[0].ip_address
    }
  }
}


# Настраиваем балансировщик для grafana
resource "yandex_lb_network_load_balancer" "grafana" {
  name = "grafana"

  listener {
    name        = "grafana-listener"
    port        = 80
    target_port = 30001
    external_address_spec {
      ip_version = "ipv4"
    }
  }
  attached_target_group {
    target_group_id = yandex_lb_target_group.k8s-nlb.id
    healthcheck {
      name = "healthcheck"
      tcp_options {
        port = 30001
      }
    }
  }

  depends_on = [yandex_lb_target_group.k8s-nlb]
}

# Настраиваем балансировщик для nginx
resource "yandex_lb_network_load_balancer" "nginx" {
  name = "nginx"
  listener {
    name        = "nginx-listener"
    port        = 80
    target_port = 30002
    external_address_spec {
      ip_version = "ipv4"
    }
  }
  attached_target_group {
    target_group_id = yandex_lb_target_group.k8s-nlb.id
    healthcheck {
      name = "healthcheck"
      tcp_options {
        port = 30002
      }
    }
  }
  depends_on = [yandex_lb_network_load_balancer.grafana]
}


