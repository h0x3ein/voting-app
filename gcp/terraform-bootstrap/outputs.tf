output "tf_bucket_name" {
  description = "The name of the Terraform state bucket."
  value       = google_storage_bucket.tf_bucket.name
}

output "tf_bucket_url" {
  description = "The full GCS URL of the Terraform state bucket."
  value       = "gs://${google_storage_bucket.tf_bucket.name}"
}
