#Создаем сервисный аккаунт и бакет где впоследствии будет хранится состояние tfstate
resource "yandex_iam_service_account" "sa" {
  name = "storage-user"
}

# Назначение роли сервисному аккаунту
resource "yandex_resourcemanager_folder_iam_member" "storage-admin" {
  folder_id = var.folder_id
  role      = "storage.admin"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
  depends_on = [yandex_iam_service_account.sa]
}

#Назначение роли для шифрования и расшифрования файлов при загрузке
resource "yandex_resourcemanager_folder_iam_member" "storage-kms-admin" {
  folder_id = var.folder_id
  role      = "kms.keys.encrypterDecrypter"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}


# Создание статического ключа доступа
resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = yandex_iam_service_account.sa.id
  description        = "static access key for object storage"
}

# Создание kms ключа
resource "yandex_kms_symmetric_key" "key-a" {
  name              = "kms-key-storage"
  description       = "kms for storage"
  default_algorithm = "AES_256"
  rotation_period   = "8760h" // 1 год
}

# Создание бакета
resource "yandex_storage_bucket" "my-bucket" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket     = var.bucket
  folder_id  = var.folder_id
  max_size   = 104857600 #100Mb #1073741824 #1Gb
  default_storage_class = "STANDARD"
  depends_on = [yandex_resourcemanager_folder_iam_member.storage-admin]

#На случай сохранения старых версий
#  versioning {
#    enabled = true
#  }

#параметры шифрования
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = yandex_kms_symmetric_key.key-a.id
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

# Сохраняем секретные данные в secret.backend.tfvars
resource "local_file" "backend_keys" {
  content  = <<EOT
access_key = "${yandex_iam_service_account_static_access_key.sa-static-key.access_key}"
secret_key = "${yandex_iam_service_account_static_access_key.sa-static-key.secret_key}"
EOT
  filename = "${path.module}/secret.backend.tfvars"
}


#terraform output access_key
#terraform output secret_key
