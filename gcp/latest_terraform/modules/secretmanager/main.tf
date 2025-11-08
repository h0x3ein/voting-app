resource "google_secret_manager_secret" "mysql_password" {
  secret_id =  "mysql-password"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "mysql_root_password" {
  secret_id = "mysql-root-password"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "mysql_user" {
  secret_id = "mysql-user"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "mysql_password_version" {
  secret = google_secret_manager_secret.mysql_password.id
  secret_data = var.mysql_password
}

resource "google_secret_manager_secret_version" "mysql_root_password_version" {
  secret = google_secret_manager_secret.mysql_root_password.id
  secret_data = var.mysql_root_password
}


resource "google_secret_manager_secret_version" "mysql_user_version" {
  secret = google_secret_manager_secret.mysql_user.id
  secret_data = var.mysql_user
}