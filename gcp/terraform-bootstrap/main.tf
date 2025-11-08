resource "google_storage_bucket" "tf_bucket" {
  name     = "my-lab-tfstate-${var.project_id}"
  location = var.region

  versioning {
    enabled = true
  }
}
