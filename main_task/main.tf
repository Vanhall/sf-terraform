terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">=0.61.0"
    }
  }

  backend "s3" {
    endpoints = {
      s3 = "http://storage.yandexcloud.net"
    }
    bucket     = "tf-state-bucket-vnh"
    region     = "ru-central1-a"
    key        = "terraform.tfstate"
    access_key = ""
    secret_key = ""

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
  }

  required_version = "~> 1.6.0"
}

provider "yandex" {
  service_account_key_file = file("~/sf/yac-key.json")
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone[0]
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = var.zone[0]
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_vpc_subnet" "subnet-2" {
  name           = "subnet2"
  zone           = var.zone[1]
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.11.0/24"]
}


module "ya_instance_1" {
  source                = "./modules/instance"
  instance_family_image = "lemp"
  vpc_subnet_id         = yandex_vpc_subnet.subnet-1.id
  instance_zone         = var.zone[0]
}

module "ya_instance_2" {
  source                = "./modules/instance"
  instance_family_image = "lamp"
  vpc_subnet_id         = yandex_vpc_subnet.subnet-2.id
  instance_zone         = var.zone[1]
}

resource "yandex_lb_target_group" "target-group-1" {
  name      = "my-target-group"
  folder_id = var.folder_id

  target {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    address   = module.ya_instance_1.internal_ip_address_vm
  }

  target {
    subnet_id = yandex_vpc_subnet.subnet-2.id
    address   = module.ya_instance_2.internal_ip_address_vm
  }
}

resource "yandex_lb_network_load_balancer" "load-balancer-1" {
  name      = "my-load-balancer"
  folder_id = var.folder_id

  listener {
    name = "http-listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.target-group-1.id

    healthcheck {
      name = "default-healthcheck"
      http_options {
        port = 80
      }
    }
  }
}
