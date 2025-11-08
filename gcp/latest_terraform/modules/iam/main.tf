resource "google_service_account" "eso-sa" {
  account_id = var.service_account_name
  display_name = "ESO Service Account"
}

resource "google_project_iam_member" "eso_secret_accessor" {
  project = var.project_id
  member = "serviceAccount:${google_service_account.eso-sa.email}"
  role ="roles/secretmanager.secretAccessor"
}

resource "google_service_account_key" "eso_key" {
  service_account_id = google_service_account.eso-sa.name
}