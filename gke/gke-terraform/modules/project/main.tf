locals {
  api = [
    "container.googleapis.com",
    "compute.googleapis.com",
    "servicenetworking.googleapis.com",
    "redis.googleapis.com",
    "sqladmin.googleapis.com"
  ]
}

resource "google_project_service" "enable" {
  for_each           = toset(local.api)
  service            = each.value
  project            = var.project_id
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

# -----------------------------------------------------------------------------
# Cloud SQL Service Account & Workload Identity
# -----------------------------------------------------------------------------

resource "google_service_account" "cloud_sql_sa" {
  account_id   = "${var.instance_name}-sa"
  display_name = "Cloud SQL Service Account for ${var.instance_name}"
  project      = var.project_id
}

resource "google_project_iam_member" "cloud_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.cloud_sql_sa.email}"
}

# NOTE: Workload Identity binding moved to root-level workload_identity.tf
# Reason: Binding requires GKE cluster to exist first (to create the identity pool).
# This avoids circular dependency: project module → GKE module → needs identity pool from project.
# The binding is now created with explicit depends_on = [module.gke] at root level.

resource "google_project_iam_member" "gke_nodes_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}
