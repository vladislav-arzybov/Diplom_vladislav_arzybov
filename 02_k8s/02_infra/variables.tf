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


###VM vars
variable "vm_data_family" {
  type        = string
  default     = "ubuntu-2204-lts"
  description = "The name of the image family to which this image belongs"
}

variable "platform_id" {
  type        = string
  default     = "standard-v3"
  description = "The type of virtual machine to create"
}
variable "vm_scheduling_policy_preemptible" {
  type        = bool
  default     = true
  description = "Specifies if the instance is preemptible"
}
variable "serial-port" {
  type        = number
  default     = 1
  description = "ssh-keygen console"
}

variable "user" {
  type        = string
  default     = "reivol"
  description = "ssh autorization"
}

/*
locals {
  ssh-key = file("~/.ssh/id_rsa.pub")
}
*/

#ssh key for VM + atlantis
variable "ssh_public_key" {
  type        = string
  description = "SSH public key"
}

###VM resourse

locals {
  subnets = {
    "subnet-a" = yandex_vpc_subnet.subnet-a.id
    "subnet-b" = yandex_vpc_subnet.subnet-b.id
    "subnet-d" = yandex_vpc_subnet.subnet-d.id
  }
}

variable "each_vm" {
  type = map(object({
    name     = string
    hostname = string
    cpu         = number
    ram         = number
    disk_volume = number
    fraction    = number
    subnet      = string
    zone        = string
  }))
  default = {
    master-node-1 = {
      name     = "master-node-1"
      hostname = "master-node-1"
      cpu         = 4
      ram         = 4
      disk_volume = 40
      fraction    = 20
      subnet      = "subnet-a"
      zone        = "ru-central1-a"
    },
    worker-node-1 = {
      name     = "worker-node-1"
      hostname = "worker-node-1"
      cpu         = 4
      ram         = 4
      disk_volume = 40
      fraction    = 20
      subnet      = "subnet-b"
      zone        = "ru-central1-b"
    },
    worker-node-2 = {
      name     = "worker-node-2"
      hostname = "worker-node-2"
      cpu         = 4
      ram         = 4
      disk_volume = 40
      fraction    = 20
      subnet      = "subnet-d"
      zone        = "ru-central1-d"
    }
  }
}