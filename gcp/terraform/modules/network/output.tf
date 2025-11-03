output "network_name" {
  description = "The name of the VPC network created or used."
  value       = google_compute_network.vpc.name
}

output "network_self_link" {
  description = "The self link of the VPC network (used by other modules like Redis)."
  value       = google_compute_network.vpc.self_link
}
