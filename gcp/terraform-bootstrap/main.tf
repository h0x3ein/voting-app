resource "google_storage_bucket" "tf_bucket" {
  name     = "my-lab-tfstate-${var.project_id}"
  location = var.region
  project  = var.project_id

  versioning {
    enabled = true
  }
}