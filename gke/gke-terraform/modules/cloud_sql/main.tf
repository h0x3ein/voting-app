resource "google_sql_database_instance" "master" {
  name             = var.instance_name
  database_version = var.database_version
  region           = var.region
  project          = var.project_id

  # For learning/labs, disable deletion protection to allow easy cleanup
  deletion_protection = false

  settings {
    tier = var.tier

    # Zonal availability is cheaper than HA (High Availability)
    availability_type = "ZONAL"

    ip_configuration {
      ipv4_enabled    = false # No public IP
      private_network = var.private_network_id
    }

    # Optional: Maintenance window
    # maintenance_window {
    #   day  = 7  # Sunday
    #   hour = 3  # 3 AM
    # }
  }
}

resource "google_sql_database" "default" {
  name     = var.db_name
  instance = google_sql_database_instance.master.name
  project  = var.project_id
}

resource "google_sql_user" "default" {
  name     = var.db_user
  instance = google_sql_database_instance.master.name
  password = var.db_password
  project  = var.project_id
}
