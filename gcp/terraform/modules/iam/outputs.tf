output "eso_sa_email" {
  description = "The email address of the ESO service account."
  value       = google_service_account.eso_sa.email
}