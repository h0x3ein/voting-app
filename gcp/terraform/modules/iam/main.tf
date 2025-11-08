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

resource "google_service_account_key" "eso_key" {
  service_account_id = google_service_account.eso_sa.name
}

# ==============================
# IAM Service Account Creation
# ==============================
resource "google_service_account" "cloudsql_proxy_sa" {
  project      = var.project_id
  account_id   = var.proxy_sa_name
  display_name = "Cloud SQL Proxy Service Account"

}

# ==============================
# Grant Cloud SQL Client Role
# ==============================
resource "google_project_iam_member" "proxy_sa_client_role" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloudsql_proxy_sa.email}"
}

# ==============================
# Create Service Account Key (for Cloud SQL Proxy)
# ==============================
resource "google_service_account_key" "cloudsql_proxy_key" {
  service_account_id = google_service_account.cloudsql_proxy_sa.name
}