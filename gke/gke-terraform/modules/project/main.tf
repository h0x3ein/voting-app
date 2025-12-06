locals {
  api = [
    "container.googleapis.com",
    "compute.googleapis.com",
    "servicenetworking.googleapis.com",
    "redis.googleapis.com"
  ]
}

resource "google_project_service" "enable" {
  for_each = toset(local.api)
  service  = each.value
  // it is better to define peoject for multi env or ci
  project = var.project_id
  // tell me ai this option (avoids breaking shared resources/pipelines)
  disable_on_destroy = false

}


# GKE Node Service Account
resource "google_service_account" "gke_nodes" {
  project      = var.project_id
  account_id   = "gke-nodes-sa"
  display_name = "GKE Nodes Service Account"
}


# Minimal IAM for node-level telemetry
resource "google_project_iam_member" "gke_nodes_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}