###############################################
# ☁️ Cloud SQL (MySQL) Terraform Module
###############################################

# Create the Cloud SQL instance (private IP only)
resource "google_sql_database_instance" "mysql_instance" {
  project          = var.project_id
  name             = var.db_instance_name
  region           = var.region
  database_version = "MYSQL_8_0"

  settings {
    tier = var.db_tier

    ip_configuration {
      ipv4_enabled    = false                 # ✅ Disable public IP
      private_network = var.network_self_link # ✅ Use private network from network module
    }

    activation_policy = "ALWAYS"
  }

  deletion_protection = false  # Turn on for prod
}

###############################################
# 🧱 Database and User
###############################################
resource "google_sql_database" "database" {
  name     = var.db_name
  instance = google_sql_database_instance.mysql_instance.name
  project  = var.project_id
}

resource "google_sql_user" "app_user" {
  name     = var.db_user
  instance = google_sql_database_instance.mysql_instance.name
  project  = var.project_id
  password = var.db_pass
}

###############################################
# 🔐 Cloud SQL Proxy Service Account
###############################################
resource "google_service_account" "proxy_sa" {
  project      = var.project_id
  account_id   = var.proxy_sa_name
  display_name = "Cloud SQL Proxy Service Account"
}

resource "google_project_iam_member" "proxy_sa_client_role" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.proxy_sa.email}"
}

# (Optional) Create key for manual proxy usage
resource "google_service_account_key" "proxy_sa_key" {
  service_account_id = google_service_account.proxy_sa.name
  keepers = {
    key_rotation = var.key_rotation_id
  }
}
