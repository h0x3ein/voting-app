# Create the Cloud SQL instance (private IP only)
resource "google_sql_database_instance" "mysql_instance" {
  name             = var.db_instance_name
  database_version = "MYSQL_8_0"

  settings {
    tier = var.db_tier

    ip_configuration {
      ipv4_enabled    = true               
      private_network = var.vote_vpc
    }

  }

}

# 🧱 Database and User
resource "google_sql_database" "database" {
  name     = var.db_name
  instance = google_sql_database_instance.mysql_instance.name
}

resource "google_sql_user" "app_user" {
  name     = var.db_user
  instance = google_sql_database_instance.mysql_instance.name
  password = var.db_pass
}
