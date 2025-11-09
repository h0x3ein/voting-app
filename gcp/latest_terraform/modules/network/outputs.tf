output "vote_vpc" {
  description = "The self link of the VPC network (used by Cloud SQL, Redis, etc.)"
  value       = google_compute_network.vpc.self_link
}
