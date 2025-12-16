###cloud vars
variable "cloud_id" {
  type        = string
  default     = "b1gvga9kieio1fe5p4ss"
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/cloud/get-id"
}

variable "folder_id" {
  type        = string
  default     = "b1g51e5v9mh6c4gtt2he"
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id"
}

variable "default_zone" {
  type        = string
  default     = "ru-central1-a"
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
}

variable "bucket" {
  type        = string
  default     = "vladislav-arzybov-bucket"
  description = "bucket name"
}
