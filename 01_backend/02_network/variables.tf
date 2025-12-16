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

###network vars
variable "vpc_name" {
  type        = string
  default     = "prod-vpc"
  description = "VPC network name"
}

variable "subnet-a_name" {
  type        = string
  default     = "subnet-a"
  description = "subnet name"
}
variable "subnet-b_name" {
  type        = string
  default     = "subnet-b"
  description = "subnet name"
}
variable "subnet-d_name" {
  type        = string
  default     = "subnet-d"
  description = "subnet name"
}

variable "zone-a" {
  type        = string
  default     = "ru-central1-a"
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
}
variable "zone-b" {
  type        = string
  default     = "ru-central1-b"
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
}
variable "zone-d" {
  type        = string
  default     = "ru-central1-d"
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
}

variable "subnet-a_cidr" {
  type        = list(string)
  default     = ["10.0.1.0/24"]
  description = "https://cloud.yandex.ru/docs/vpc/operations/subnet-create"
}
variable "subnet-b_cidr" {
  type        = list(string)
  default     = ["10.0.2.0/24"]
  description = "https://cloud.yandex.ru/docs/vpc/operations/subnet-create"
}
variable "subnet-d_cidr" {
  type        = list(string)
  default     = ["10.0.3.0/24"]
  description = "https://cloud.yandex.ru/docs/vpc/operations/subnet-create"
}

variable "bucket" {
  type        = string
  default     = "vladislav-arzybov-bucket"
  description = "bucket name"
}

