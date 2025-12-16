#Указываем образ для ВМ
data "yandex_compute_image" "ubuntu" {
  family = var.vm_data_family
}


#Объявляем новые переменные для cloud-init.yml
data "template_file" "cloudinit" {
  template = file("./cloud-init.yml")

    vars = {
    username           = var.user
    #ssh_public_key     = file("~/.ssh/id_rsa.pub")
    ssh_public_key     = chomp(var.ssh_public_key) #chomp необходим для удаления пустой строки в конце, особенность atlantis (Kubernetes secret)
  }

}
