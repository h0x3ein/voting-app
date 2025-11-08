output "eso_private_key" {
  description = "The ESO service account private key from the IAM module."
  value       = module.iam.eso_private_key
  sensitive   = true
}

output "cloudsql_proxy_key" {
  description = "The private key of the Cloud SQL Proxy service account."
  value       = module.iam.cloudsql_proxy_key
  sensitive   = true
}