module "project" {
  source     = "./modules/project"
  project_id = var.project_id
}

module "network" {
  source     = "./modules/network"
  project_id = var.project_id
  region     = var.region
  depends_on = [ module.project ]
}

#module "gke" {
#  source     = "./modules/gke"
#  region     = var.region
#  depends_on = [module.project, module.network]
#}
