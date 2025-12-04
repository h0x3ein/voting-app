#google_container_node_pool

#google_container_cluster

resource "google_container_cluster" "hs_gke_cluster" {
  name               = "test-cluster"
  location           = var.region
  initial_node_count = 1
}