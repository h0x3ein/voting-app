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

resource "google_compute_global_address" "private_ip_alloc" {
  name          = "managed-services-psa-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id

}

resource "google_service_networking_connection" "default" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
  depends_on = [
    google_compute_global_address.private_ip_alloc
  ]

}

# Cloud Router for Cloud NAT
resource "google_compute_router" "router" {
  name    = "${var.network_name}-router"
  region  = var.region
  network = google_compute_network.vpc.id
  project = var.project_id
}

# Cloud NAT for private GKE nodes to access internet
resource "google_compute_router_nat" "nat" {
  name    = "${var.network_name}-nat"
  router  = google_compute_router.router.name
  region  = var.region
  project = var.project_id

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}