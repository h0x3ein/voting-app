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
      ipv4_enabled    = true                 # ✅ Disable public IP
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
