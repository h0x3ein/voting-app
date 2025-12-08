output "gke_node_sa_email" {
  value = google_service_account.gke_nodes.email
}

output "cloud_sql_sa_email" {
  description = "The email of the Google Service Account created for Cloud SQL access"
  value       = google_service_account.cloud_sql_sa.email
}

output "cloud_sql_sa_name" {
  description = "The full resource name of the Cloud SQL service account (for IAM bindings)"
  value       = google_service_account.cloud_sql_sa.name
}
