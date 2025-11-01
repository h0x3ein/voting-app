resource "google_storage_bucket" "tf_bucket" {
  name      = var.tf_bucket_name
  location  = var.region
  project   = var.project_id
  
  versioning {
    enabled = true
  }
}