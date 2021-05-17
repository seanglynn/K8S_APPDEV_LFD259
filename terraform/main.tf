provider "google" {
  version = "3.5.0"

  credentials = file(var.gce_credentials_file)

  project = var.project
  region  = var.region
  zone    = var.zone
}

module "network" {
  source        = "terraform-google-modules/network/google"
  version       = "2.0.2"

  network_name  = "lfclass-terraform-vpc-network"
  project_id    = var.project

  subnets       = [
    {
      subnet_name   = "lfclass-terraform-vpc-network-subnet"
      subnet_ip     = var.cidrs[0]
      subnet_region = var.region
    },
  ]
}

resource "google_compute_firewall" "lfclass" {
  name            = "lfclass-terraform-firewall"
  network         = module.network.network_name
  source_ranges   = [ var.cidrs[1] ]

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }
}

resource "google_compute_address" "master_ip_address" {
  name = "master-external-ip"
}

resource "google_compute_instance" "master_vm_instance" {
  name            = "master"

  machine_type    = var.machine_type
  project         = var.project

  boot_disk {
    initialize_params {
      image = "${var.source_image.project}/${var.source_image.family}"
      size  = var.disk_size
    }
  }

  metadata = {
    sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }

  metadata_startup_script = var.master_startup_script

  network_interface {
    subnetwork = module.network.subnets_names[0]
    access_config {
      nat_ip       = google_compute_address.master_ip_address.address
      network_tier = "PREMIUM"
    }
  }

  service_account {
    email   = var.service_account.email
    scopes  = var.service_account.scopes
  }
}

resource "google_compute_address" "worker_ip_address" {
  name = "worker-external-ip"
}

resource "google_compute_instance" "worker_vm_instance" {
  name            = "worker"

  machine_type    = var.machine_type
  project         = var.project

  boot_disk {
    initialize_params {
      image = "${var.source_image.project}/${var.source_image.family}"
      size  = var.disk_size
    }
  }

  metadata = {
    sshKeys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }

  metadata_startup_script = var.worker_startup_script

  network_interface {
    subnetwork = module.network.subnets_names[0]
    access_config {
      nat_ip       = google_compute_address.worker_ip_address.address
      network_tier = "PREMIUM"
    }
  }

  service_account {
    email   = var.service_account.email
    scopes  = var.service_account.scopes
  }
}
