terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
  required_version = "~>1.8.4"
}

provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.default_zone
  #service_account_key_file = file("~/.authorized_key.json")
}

