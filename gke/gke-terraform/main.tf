module "project" {
  source     = "./modules/project"
  project_id = var.project_id
}

module "network" {
  source     = "./modules/network"
  project_id = var.project_id
  region     = var.region
  depends_on = [module.project]
}

module "gke" {
  source       = "./modules/gke"
  region       = var.region
  project_id   = var.project_id
  cluster_name = var.cluster_name

  network_id = module.network.network_id

  subnetwork_id = module.network.subnetwork_id

  pods_range_name     = module.network.pods_range_name
  services_range_name = module.network.services_range_name

  node_service_account_email = module.project.gke_node_sa_email

  machine_type = var.machine_type
  disk_size_gb = var.disk_size_gb
  min_nodes    = var.min_nodes
  max_nodes    = var.max_nodes

  depends_on = [module.project, module.network]
}
