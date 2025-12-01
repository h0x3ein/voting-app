locals {
  apis = [
    "secretmanager.googleapis.com",
    "sqladmin.googleapis.com",
    "redis.googleapis.com",
    "compute.googleapis.com",
    "servicenetworking.googleapis.com",
  ]
}

resource "google_project_service" "enabled" {
  for_each = toset(local.apis)
  service  = each.value
  project  = var.project_id
}