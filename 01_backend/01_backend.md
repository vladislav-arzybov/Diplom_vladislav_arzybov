### Создание облачной инфраструктуры

Для начала необходимо подготовить облачную инфраструктуру в ЯО при помощи [Terraform](https://hashicorp-releases.yandexcloud.net/terraform/).

Особенности выполнения:

- Бюджет купона ограничен, что следует иметь в виду при проектировании инфраструктуры и использовании ресурсов;
Для облачного k8s используйте региональный мастер(неотказоустойчивый). Для self-hosted k8s минимизируйте ресурсы ВМ и долю ЦПУ. В обоих вариантах используйте прерываемые ВМ для worker nodes.

Предварительная подготовка к установке и запуску Kubernetes кластера.

1. Создайте сервисный аккаунт, который будет в дальнейшем использоваться Terraform для работы с инфраструктурой с необходимыми и достаточными правами. Не стоит использовать права суперпользователя

> Через CLI создаем файл ключа ```authorized_key.json``` сервисного аккаунта ```testssh``` который в дальнейшем будет использоваться для работы с terraform
- yc iam key create --output authorized_key.json --service-account-name testssh

> Добавляем информацию в блоке настроек провайдера, чтобы в дальнейшем не вводить каждый раз ```OAuth-token``` для выполнения команд.

```
provider "yandex" {
  service_account_key_file = file("~/.authorized_key.json")
}
```

---

#### P.S. 
> Использование authorized_key.json удобно при локальном запуске Terraform, создании backend. Но т.к. в дальнейшем потребуется использовать в работе Atlantis, то строка ```service_account_key_file = file("~/.authorized_key.json")``` удалена из кода Terraform, а информация о ключе передана в переменную окруженя ```YC_SERVICE_ACCOUNT_KEY_FILE``` в ~/.bashrc.
- echo 'export YC_SERVICE_ACCOUNT_KEY_FILE="$HOME/.authorized_key.json"' >> ~/.bashrc
- source ~/.bashrc
- echo $YC_SERVICE_ACCOUNT_KEY_FILE

<img width="1130" height="75" alt="изображение" src="https://github.com/user-attachments/assets/b25a668b-effe-4356-a7ab-ae5c3057746d" />

> Также заранее добавим в переменную ```TF_VAR_ssh_public_key``` значение ssh public_key который в дальнейшем будет использоваться для подключения к ВМ
- echo 'export TF_VAR_ssh_public_key="$(cat ~/.ssh/id_rsa.pub)"' >> ~/.bashrc
- source ~/.bashrc
- echo $TF_VAR_ssh_public_key

<img width="1030" height="36" alt="изображение" src="https://github.com/user-attachments/assets/6ee42ec7-aa47-4249-a761-dba041b61d32" />

---

2. Подготовьте [backend](https://developer.hashicorp.com/terraform/language/backend) для Terraform:  
   а. Рекомендуемый вариант: [S3 bucket](https://ru.hexlet.io/courses/terraform-basics/lessons/remote-state/theory_unit) в созданном ЯО аккаунте(создание бакета через TF)
   б. Альтернативный вариант:  [Terraform Cloud](https://app.terraform.io/)

> Выполним предварительную настройку для создания Object Storage в YC, где в дальнейшем будет храниться текущее состояние проекта, файл .tfstate

> Чтобы обеспечить конфиденциальность ```access_key``` и ```secret_key``` для удобства сохраним их в файл ```secret.backend.tfvars```, т.к. проект который создает bucket выполняется отдельно от проекта использующего S3 хранилище.   
> Для этого используем ресурс ```local_file```, добавляем в блок провайдеров провайдера ```hashicorp/local```

```
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
```

> Cохраняем ключи в файл ```secret.backend.tfvars```

```
resource "local_file" "backend_keys" {
  content  = <<EOT
access_key = "${yandex_iam_service_account_static_access_key.sa-static-key.access_key}"
secret_key = "${yandex_iam_service_account_static_access_key.sa-static-key.secret_key}"
EOT
  filename = "${path.module}/secret.backend.tfvars"
}
```

> Выпоняем terraform init, plan, apply.

> Для проверки корректности автозаполнения файла ```secret.backend.tfvars``` его содержимое можно сверить с выводом команд:
- terraform output access_key
- terraform output secret_key

Проверяем успешное создание бакета в яндекс облаке.

<img width="822" height="250" alt="изображение" src="https://github.com/user-attachments/assets/46be7422-899b-4e7d-b4fc-2de4d574a1b3" />

---

3. Создайте конфигурацию Terrafrom, используя созданный бакет ранее как бекенд для хранения стейт файла. Конфигурации Terraform для создания сервисного аккаунта и бакета и основной инфраструктуры следует сохранить в разных папках.

> Файл ```secret.backend.tfvars``` копируем в каталог из которго будет разворачиваться инфраструктура проекта.

> Чтобы добавить данные из файла ```secret.backend.tfvars``` при инициации инфраструктуры нужно выполнить команду: 
- terraform init -backend-config=secret.backend.tfvars

<img width="832" height="120" alt="изображение" src="https://github.com/user-attachments/assets/ccca2f40-ee76-48b0-951c-71e77ee2688e" />

> Таким образом можно сохранить в безопасности секретные данные и не указывать их в конфиге ```backend.tf```

```
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
```

> Проверяем наличие файла в бакете

<img width="924" height="417" alt="изображение" src="https://github.com/user-attachments/assets/cc8c642a-19c9-4fc8-87c5-2ab4a49d03c6" />

> Проверяем что локальном в файле .terraform/terraform.tfstate присутствует лишь информация об удаленном хранилище:

<img width="474" height="61" alt="изображение" src="https://github.com/user-attachments/assets/d2b1ce61-1d3a-442c-9739-d5206b55dbb9" />

---

4. Создайте VPC с подсетями в разных зонах доступности.

```
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
```

---

5. Убедитесь, что теперь вы можете выполнить команды `terraform destroy` и `terraform apply` без дополнительных ручных действий.

<img width="647" height="282" alt="изображение" src="https://github.com/user-attachments/assets/b218f805-6238-4d86-bf20-404680908071" />

---

6. В случае использования [Terraform Cloud](https://app.terraform.io/) в качестве [backend](https://developer.hashicorp.com/terraform/language/backend) убедитесь, что применение изменений успешно проходит, используя web-интерфейс Terraform cloud.

Ожидаемые результаты:

1. Terraform сконфигурирован и создание инфраструктуры посредством Terraform возможно без дополнительных ручных действий, стейт основной конфигурации сохраняется в бакете или Terraform Cloud
2. Полученная конфигурация инфраструктуры является предварительной, поэтому в ходе дальнейшего выполнения задания возможны изменения.

> Ссылки на конфигурационные файлы Terraform созданные для выполнения данного блока:
- [bucket](https://github.com/vladislav-arzybov/HOMEWORK/tree/main/23_Diplom/01_backend/01_bucket)
- [backend + network](https://github.com/vladislav-arzybov/HOMEWORK/tree/main/23_Diplom/01_backend/02_network)


