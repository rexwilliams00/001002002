#Task 2

terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "5.25.0"
    }
  }
}

provider "google" {
  # Configuration options
project = "class5-5green"
region = "us-central1"
zone = "us-central1-a"
credentials = "class5-5green-298b62a3188e.json"
}

resource "google_compute_network" "vpc-tf" {
  name = "auto-vpc-tf"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "sub-sg" {
  name = "sub-sg"
  network = google_compute_network.vpc-tf.id
  ip_cidr_range = "107.171.0.0/17"
  region = "us-central1"
  private_ip_google_access = false
}

resource "google_compute_instance" "vm_instance" {
  project = "class5-5green"
  name = "armageddon-vm"  
  zone = "us-central1-a"
  machine_type = "e2-standard-4"
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
      }
  }

  tags = ["http-server"]
  
  network_interface {
    subnetwork = google_compute_subnetwork.sub-sg.self_link
    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    startup-script = "#Danke Remo\n#!/bin/bash\n# Update and install Apache2\necho \"Running startup script. . .\"\napt update\napt install -y apache2\n\n# Start and enable Apache2\nsystemctl start apache2\nsystemctl enable apache2\n\n# GCP Metadata server base URL and header\nMETADATA_URL=\"http://metadata.google.internal/computeMetadata/v1\"\nMETADATA_FLAVOR_HEADER=\"Metadata-Flavor: Google\"\n\n# Use curl to fetch instance metadata\nlocal_ipv4=$(curl -H \"$${METADATA_FLAVOR_HEADER}\" -s \"$${METADATA_URL}/instance/network-interfaces/0/ip\")\nzone=$(curl -H \"$${METADATA_FLAVOR_HEADER}\" -s \"$${METADATA_URL}/instance/zone\")\nproject_id=$(curl -H \"$${METADATA_FLAVOR_HEADER}\" -s \"$${METADATA_URL}/project/project-id\")\nnetwork_tags=$(curl -H \"$${METADATA_FLAVOR_HEADER}\" -s \"$${METADATA_URL}/instance/tags\")\n\n# Create a simple HTML page and include instance details\ncat <<EOF > /var/www/html/index.html\n<html><body>\n<h2>Welcome to your custom website.</h2>\n<h3>Created with a direct input startup script!</h3>\n<p><b>Instance Name:</b> $(hostname -f)</p>\n<p><b>Instance Private IP Address: </b> $local_ipv4</p>\n<p><b>Zone: </b> $zone</p>\n<p><b>Project ID:</b> $project_id</p>\n<p><b>Network Tags:</b> $network_tags</p>\n</body></html>\nEOF"
  }


}

resource "google_compute_firewall" "http_firewall" {
  name = "allow-http"
  network = google_compute_network.vpc-tf.self_link

  allow{
    protocol = "tcp"
    ports = [80]
  }

  source_ranges = ["0.0.0.0/0"]
}


output "auto" {
  value = google_compute_network.vpc-tf.id
}

output "public_ip" {
  value = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
}

output "external_ip" {
  value = "http://${google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip}"
}

output "vpc_name" {
  value = google_compute_network.vpc-tf.name
}

output "subnet_cidr" {
  value = google_compute_subnetwork.sub-sg.ip_cidr_range
}

output "internal_ip" {
  value = google_compute_instance.vm_instance.network_interface.0.network_ip
}

#End of Task 2