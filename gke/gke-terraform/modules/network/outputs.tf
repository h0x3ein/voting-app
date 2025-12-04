output "network_name" {
  value = google_compute_network.vpc.name
}

output "subnet_name" {
  value = google_compute_subnetwork.subnet.name
}

output "pods_range_name" {
  value = var.pods_range_name
}

output "services_range_name" {
  value = var.services_range_name
}

output "network_id" {
  value = google_compute_network.vpc.id
}

output "subnetwork_id" {
  value = google_compute_subnetwork.subnet.id
}