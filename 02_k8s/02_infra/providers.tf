terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.2"
    }
    yandex = {
      source = "yandex-cloud/yandex"
      version = ">= 0.100, < 0.200"
    }
  }
  required_version = "~>1.11.3"
}

provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone-a
  #service_account_key_file = file("~/.authorized_key.json")
}

