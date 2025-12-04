module "project" {
  source = "./modules/project"
}


module "gke" {
  source = "./modules/gke"
  region = var.region
  depends_on = [ module.project ]
}
