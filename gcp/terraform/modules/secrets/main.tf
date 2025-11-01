# Enable Secret Manager API (safe to run if already enabled)
resource "google_project_service" "secretmanager_api" {
  project = var.project_id
  service = "secretmanager.googleapis.com"
}

# Create three secrets (static list for simplicity)
resource "google_secret_manager_secret" "mysql_password" {
  project   = var.project_id
  secret_id = "mysql-password"

  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager_api]
}

resource "google_secret_manager_secret" "mysql_root_password" {
  project   = var.project_id
  secret_id = "mysql-root-password"

  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager_api]
}

resource "google_secret_manager_secret" "mysql_user" {
  project   = var.project_id
  secret_id = "mysql-user"

  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager_api]
}