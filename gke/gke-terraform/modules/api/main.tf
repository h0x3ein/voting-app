locals {
  api=[
    "container.googleapis.com"
  ]
}

resource "google_project_service" "enable" {
  for_each = toset(local.api)
  service = each.value
}