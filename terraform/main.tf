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
  source_ranges   = ["0.0.0.0/0", var.cidrs[0], var.cidrs[1]]

  allow {
    protocol = "tcp"
//    ports = ["22", "80","53", "443", "6443", "8443", "8000", "10000-20000"]
  }

  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "sctp"
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
      // Use var.static_ip if defined
//      nat_ip = var.static_ip != "" ? var.static_ip : google_compute_address.master_ip_address.address
//      nat_ip       = var.static_ip
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
  provisioner "file" {
    connection {
      private_key = file(var.gce_ssh_private_key_file)
      user        = var.gce_ssh_user
      type        = "ssh"
      host = google_compute_address.master_ip_address.address
    }

    destination = "setup"
    source      = "../SOLUTIONS/setup"
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
      "sudo cp -f /etc/kubernetes/admin.conf /home/${var.gce_ssh_user}/.kube/config",
      "wget https://training.linuxfoundation.org/cm/LFD259/LFD259_V2021-05-21_SOLUTIONS.tar.xz --user=${var.lfd_username} --password=${var.lfd_pw} -O /home/${var.gce_ssh_user}/LFD259_SOLUTIONS.tar.xz && tar -xvf /home/${var.gce_ssh_user}/LFD259_SOLUTIONS.tar.xz ",
      "kubectl create serviceaccount ${var.gce_ssh_user}",
      "echo 'alias k=kubectl'  >> ~/.bashrc",
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




