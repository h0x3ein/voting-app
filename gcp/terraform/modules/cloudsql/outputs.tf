###############################################
# 📤 Outputs for Cloud SQL Module
###############################################

output "instance_connection_name" {
  description = "The full connection name of the Cloud SQL instance."
  value       = google_sql_database_instance.mysql_instance.connection_name
}

output "proxy_sa_email" {
  description = "The email address of the proxy service account."
  value       = google_service_account.proxy_sa.email
}

output "db_instance_name" {
  description = "The name of the Cloud SQL instance."
  value       = google_sql_database_instance.mysql_instance.name
}

output "db_user" {
  description = "The app database username."
  value       = google_sql_user.app_user.name
}

output "db_name" {
  description = "The name of the created database."
  value       = google_sql_database.database.name
}