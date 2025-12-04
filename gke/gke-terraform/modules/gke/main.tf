#google_container_node_pool

#google_container_cluster

resource "google_container_cluster" "gke" {
  name                     = var.cluster_name
  project                  = var.project_id
  location                 = var.region
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = var.network_id
  subnetwork = var.subnetwork_id

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}

resource "google_container_node_pool" "general" {
  project  = var.project_id
  name     = "general"
  location = var.region
  cluster  = google_container_cluster.gke.name

  autoscaling {
    min_node_count = var.min_nodes
    max_node_count = var.max_nodes
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type    = var.machine_type
    disk_size_gb    = var.disk_size_gb
    service_account = var.node_service_account_email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}