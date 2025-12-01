module "api" {
  source = "./modules/api"
}


module "gke" {
  source = "./modules/gke"
  region = var.region
  depends_on = [ module.api ]
}
