output "eso_key" {
  value = google_service_account_key.eso_key.private_key
}

output "cloudsql_proxy_key" {
  description = "The private key of the Cloud SQL Proxy service account."
  value       = google_service_account_key.cloudsql_proxy_key.private_key
  sensitive   = true
}