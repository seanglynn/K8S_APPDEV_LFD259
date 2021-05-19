project = "project-id"
cidrs = ["10.2.0.0/16", "10.1.0.0/16"]
disk_size = "20"
gce_credentials_file = "key.json"
gce_ssh_pub_key_file = "~/.ssh/id_rsa.pub"
gce_ssh_user = "service-account"
machine_type = "n1-standard-2"
master_startup_script = "../SOLUTIONS/s_02/k8sMaster.sh"
num_instances = 2
region= "us-central1"
service_account = {
    email  = "service-account@project-id.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
}
source_image = {
    family  = "ubuntu-1804-lts"
    project = "ubuntu-os-cloud"
}
worker_startup_script= "../SOLUTIONS/s_02/k8sSecond.sh"
zone = "us-central1-c"
