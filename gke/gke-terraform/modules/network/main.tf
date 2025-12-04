# google_compute_network
# google_compute_subnetwork
# define secondary_ip_range (for pods and services)

resource "google_compute_network" "vpc" {
  name    = var.network_name
  project = var.project_id
  # we control subnets/CIDRs for GKE 
  auto_create_subnetworks = false

}

resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  network       = google_compute_network.vpc.id
  project       = var.project_id
  region        = var.region
  ip_cidr_range = var.subnet_primary_cidr

  secondary_ip_range {
    range_name    = var.pods_range_name
    ip_cidr_range = var.pods_secondary_cidr
  }

  secondary_ip_range {
    range_name    = var.services_range_name
    ip_cidr_range = var.services_secondary_cidr
  }
}