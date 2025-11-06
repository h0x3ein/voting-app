###############################################
# 📤 Outputs for Cloud SQL Module
###############################################

output "instance_connection_name" {
  description = "Full connection name of the Cloud SQL instance."
  value       = google_sql_database_instance.mysql_instance.connection_name
}

output "private_ip_address" {
  description = "Private IP address of the Cloud SQL instance."
  value       = google_sql_database_instance.mysql_instance.private_ip_address
}

output "proxy_sa_email" {
  description = "Email address of the Cloud SQL Proxy service account."
  value       = google_service_account.proxy_sa.email
}

output "db_instance_name" {
  description = "Name of the Cloud SQL instance."
  value       = google_sql_database_instance.mysql_instance.name
}

output "db_user" {
  description = "App database username."
  value       = google_sql_user.app_user.name
}

output "db_name" {
  description = "Database name inside the instance."
  value       = google_sql_database.database.name
}
