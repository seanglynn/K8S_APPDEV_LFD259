variable "project" {
  type = string
  default = "sodium-hangar-309319"
}

variable "cidrs" {
  type = list
  default = ["10.1.0.0/16", "10.2.0.0/16"]
}

variable "disk_size" {
  type = string
  default = "20"
}

variable "gce_credentials_file" {
  type = string
}
variable "gce_ssh_pub_key_file" {
  type = string
}
variable "gce_ssh_private_key_file" {
  type = string
}
variable "gce_ssh_user" {
  type = string
}

variable "machine_type" {
  type = string
  default = "n1-standard-2"
}
variable "master_startup_script" {
  type = string
  default = "../SOLUTIONS/s_02/k8sMaster.sh"
}
variable "num_instances" {
  type = number
  default = 2
}

variable "region" {
  type = string
  default = "us-central1"
}
variable "service_account" {
  type = object({
    email  = string
    scopes = set(string)
  })
}

variable "source_image" {
  type = object({
    family  = string
    project = string
  })
  default = {
    family  = "ubuntu-1804-lts"
    project = "ubuntu-os-cloud"
  }
}

variable "worker_startup_script" {
  type = string
  default = "../SOLUTIONS/s_02/k8sSecond.sh"
}

variable "zone" {
  type = string
  default = "us-central1-c"
}
