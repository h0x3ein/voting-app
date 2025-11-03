output "eso_sa_email" {
  description = "The email address of the ESO service account."
  value       = google_service_account.eso_sa.email
}

output "eso_private_key" {
  description = "The base64-encoded private key for the ESO service account."
  value       = google_service_account_key.eso_key.private_key
  sensitive   = true
}