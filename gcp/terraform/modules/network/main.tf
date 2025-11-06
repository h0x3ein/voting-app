###############################################
# 🕸️ VPC Network
###############################################
resource "google_compute_network" "vpc" {
  name                    = var.network_name
  project                 = var.project_id
  auto_create_subnetworks = true
}

###############################################
# 🔌 Private Service Access (PSA)
###############################################
# Google best practice: single shared range for all managed services (Cloud SQL, Redis, etc.)
resource "google_compute_global_address" "google_managed_services_range" {
  name          = "google-managed-services-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 24
  address       = "10.0.0.0"
  network       = google_compute_network.vpc.self_link
  project       = var.project_id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.google_managed_services_range.name]

  depends_on = [
    google_compute_global_address.google_managed_services_range
  ]
}

###############################################
# 🌐 Cloud Router + NAT (for outbound internet)
###############################################
resource "google_compute_router" "router" {
  name    = "default-router"
  network = google_compute_network.vpc.name
  region  = var.region
  project = var.project_id
}

resource "google_compute_router_nat" "nat" {
  name                               = "default-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  project                            = var.project_id
}


###############################################
# 🔥 Firewall Rules
###############################################

# Allow Redis access (TCP 6379) — optional if only internal access is needed
resource "google_compute_firewall" "allow_redis" {
  name    = "allow-redis-proxy-6379"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["6379"]
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"] # for demo; narrow to specific range for prod
  target_tags   = ["redis-proxy"]
  priority      = 1000
}

# Allow SSH via IAP (no public IP required)
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "allow-iap-ssh"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"] # IAP tunnel IP range
  target_tags   = ["redis-proxy"]
  priority      = 1000
}
