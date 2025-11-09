resource "google_compute_network" "vpc" {
  name                    = vote-app-vpc
}

# 🔌 Private Service Access (PSA)

resource "google_compute_global_address" "google_managed_services_range" {
  name          = "google-managed-services-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 20
  address       = "10.50.0.0"
  network       = google_compute_network.vpc.id

}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.google_managed_services_range]
  depends_on = []
}

# 🌐 Cloud Router + NAT (for outbound internet)

resource "google_compute_router" "router" {
  name    = "default-router"
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "default-nat"
  router                             = google_compute_router.router.name
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# 🔥 Firewall Rules
resource "google_compute_firewall" "allow_redis" {
  name = "allow-redis-proxy-6379"
  network = google_compute_network.vpc.id
  allow {
    protocol = "tcp"
    ports = [ "6379" ]
  }
  source_ranges = [ "0.0.0.0/24" ]
  target_tags = ["redis-proxy"]
}

resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "allow-iap-ssh"
  network = google_compute_network.vpc.id
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["35.235.240.0/20"]
}
