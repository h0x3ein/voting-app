###############################################
# 🕸️ VPC Network
###############################################
resource "google_compute_network" "vpc" {
  name                    = var.network_name
  project                 = var.project_id
  auto_create_subnetworks = true
}

###############################################
# 🔌 Private Service Access (PSA) Ranges
###############################################

# Reserved IP range for Redis
resource "google_compute_global_address" "redis_private_ip_range" {
  name          = "google-managed-services-range-redis"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 24
  address       = "10.0.0.0"  # Redis range
  network       = google_compute_network.vpc.self_link
  project       = var.project_id
}

# Reserved IP range for Cloud SQL
resource "google_compute_global_address" "cloudsql_private_ip_range" {
  name          = "google-managed-services-range-cloudsql"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 24
  address       = "10.0.1.0"  # Cloud SQL range (different block)
  network       = google_compute_network.vpc.self_link
  project       = var.project_id
}

###############################################
# 🧩 Private Service Networking Connections
###############################################
# Connect both ranges to Google services
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [
    google_compute_global_address.redis_private_ip_range.name,
    google_compute_global_address.cloudsql_private_ip_range.name
  ]
  depends_on = [
    google_compute_global_address.redis_private_ip_range,
    google_compute_global_address.cloudsql_private_ip_range
  ]
}

###############################################
# 🌐 Cloud Router + NAT
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
# 🔥 Firewall Rule (for Redis Proxy)
###############################################
resource "google_compute_firewall" "allow_redis" {
  name    = "allow-redis-proxy-6379"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["6379"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["redis-proxy"]
  direction     = "INGRESS"
}
