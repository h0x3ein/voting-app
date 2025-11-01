# Create the ESO Service Account
resource "google_service_account" "eso_sa" {
  project      = var.project_id
  account_id   = var.service_account_name
  display_name = "ESO Service Account"
}

# Grant Secret Manager access (read-only)
resource "google_project_iam_member" "eso_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.eso_sa.email}"
}
