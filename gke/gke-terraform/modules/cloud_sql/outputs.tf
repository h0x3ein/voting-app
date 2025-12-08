output "instance_connection_name" {
  description = "The connection name of the master instance to be used in connection strings"
  value       = google_sql_database_instance.master.connection_name
}

output "private_ip_address" {
  description = "The private IP address of the master instance"
  value       = google_sql_database_instance.master.private_ip_address
}

output "instance_name" {
  value = google_sql_database_instance.master.name
}
