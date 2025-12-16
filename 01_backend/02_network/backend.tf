terraform {
  backend "s3" {
    endpoints = {
      s3 =       "https://storage.yandexcloud.net"
    }
    bucket           = "vladislav-arzybov-bucket"       # имя бакета
    key              = "terraform/state.tfstate"  # путь в бакете
    region           = "ru-central1"
    use_path_style = true #Для корректного обращения к S3 хранилищу, https://storage.yandexcloud.net/....
    skip_region_validation      = true #отключает проверку AWS-региона
    skip_credentials_validation = true #отключает проверку ключей через AWS STS
    skip_requesting_account_id  = true #не пытаться получить AWS account ID
  }
}


#terraform init -backend-config=secret.backend.tfvars
