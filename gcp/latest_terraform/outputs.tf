output "eso_key" {
  value     = module.iam.eso_key
  sensitive = true
}

output "cloudsql_proxy_key" {
  description = "The private key of the Cloud SQL Proxy service account."
  value       = module.iam.cloudsql_proxy_key
  sensitive   = true
}