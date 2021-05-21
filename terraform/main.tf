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

  network_name  = "k8sappdev-terraform-vpc-network"
  project_id    = var.project

  subnets       = [
    {
      subnet_name   = "k8sappdev-terraform-vpc-network-subnet"
      subnet_ip     = var.cidrs[1]
      subnet_region = var.region
    },
  ]
}

resource "google_compute_firewall" "k8sappdev" {
  name            = "k8sappdev-terraform-firewall"
  network         = module.network.network_name
  source_ranges   = [ var.cidrs[1] ]

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }
}
resource "google_compute_firewall" "ssh-rule" {
  name = "allow-ssh"
  network         = module.network.network_name
  allow {
    protocol = "tcp"
    ports = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
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
  provisioner "file" {
    connection {
      private_key = file(var.gce_ssh_private_key_file)
      user        = var.gce_ssh_user
      type        = "ssh"
      host = google_compute_address.master_ip_address.address
    }

    destination = "k8sMaster.sh"
    source      = var.master_startup_script
  }

  provisioner "remote-exec" {
    connection {
      private_key = file(var.gce_ssh_private_key_file)
      user        = var.gce_ssh_user
      type        = "ssh"
      host = google_compute_address.master_ip_address.address
    }
    inline = [
      "cd /home/${var.gce_ssh_user}",
      "chmod u+x k8sMaster.sh",
      "bash k8sMaster.sh | tee $HOME/master.out",
    ]
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

  provisioner "file" {
    connection {
      private_key = file(var.gce_ssh_private_key_file)
      user        = var.gce_ssh_user
      type        = "ssh"
      host = google_compute_address.worker_ip_address.address
    }

    destination = "k8sWorker.sh"
    source      = var.worker_startup_script
  }

  provisioner "remote-exec" {
    connection {
      private_key = file(var.gce_ssh_private_key_file)
      user        = var.gce_ssh_user
      type        = "ssh"
      host = google_compute_address.worker_ip_address.address
    }
    inline = [
      "cd /home/${var.gce_ssh_user}",
      "chmod u+x k8sWorker.sh",
      "bash k8sWorker.sh | tee $HOME/worker.out",
    ]
  }

}




