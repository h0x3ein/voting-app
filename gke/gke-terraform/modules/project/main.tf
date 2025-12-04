locals {
  api=[
    "container.googleapis.com",
    "compute.googleapis.com"
  ]
}

resource "google_project_service" "enable" {
  for_each = toset(local.api)
  service = each.value
  // it is better to define peoject for multi env or ci
  project = var.project_id
  // tell me ai this option (avoids breaking shared resources/pipelines)
  disable_on_destroy = false

}