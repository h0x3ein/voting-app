locals {
  api=[
    "secretmanager.googleapis.com",
    "redis.googleapis.com",
    "compute.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",

  ]
}

resource "google_project_service" "enable" {
  for_each = toset(local.api)
  service = each.value
}