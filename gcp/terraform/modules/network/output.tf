output "network_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "network_self_link" {
  description = "The self link of the VPC network (used by Cloud SQL, Redis, etc.)"
  value       = google_compute_network.vpc.self_link
}

output "private_vpc_connection_id" {
  description = "Private Service Networking connection ID"
  value       = google_service_networking_connection.private_vpc_connection.id
}
