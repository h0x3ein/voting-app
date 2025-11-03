# 1️⃣ Create Secret Containers
resource "google_secret_manager_secret" "mysql_password" {
  project   = var.project_id
  secret_id = "MYSQL_PASSWORD"

  replication {
    auto {}
  }

}

resource "google_secret_manager_secret" "mysql_root_password" {
  project   = var.project_id
  secret_id = "MYSQL_ROOT_PASSWORD"

  replication {
    auto {}
  }

}

resource "google_secret_manager_secret" "mysql_user" {
  project   = var.project_id
  secret_id = "MYSQL_USER"

  replication {
    auto {}
  }

}

# 2️⃣ Add Secret Values (Versions)
resource "google_secret_manager_secret_version" "mysql_password_version" {
  secret      = google_secret_manager_secret.mysql_password.id
  secret_data = var.mysql_password_value
}

resource "google_secret_manager_secret_version" "mysql_root_password_version" {
  secret      = google_secret_manager_secret.mysql_root_password.id
  secret_data = var.mysql_root_password_value
}

resource "google_secret_manager_secret_version" "mysql_user_version" {
  secret      = google_secret_manager_secret.mysql_user.id
  secret_data = var.mysql_user_value
}