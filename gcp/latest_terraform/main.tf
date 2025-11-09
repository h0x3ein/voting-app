module "api" {
  source = "./modules/api"
}

module "iam" {
  source     = "./modules/iam"
  project_id = var.project_id
}

module "secretmanager" {
  source              = "./modules/secretmanager"
  mysql_root_password = var.mysql_root_password
  mysql_password      = var.mysql_password
  mysql_user          = var.mysql_user
  depends_on          = [module.api]
}

module "network" {
  source = "./modules/network"
}


module "vm" {
  source     = "./modules/vm"
  name       = "redis-proxy"
  depends_on = [module.api]
  zone       = var.zone
  network    = module.network.vote_vpc
}


module "redis" {
  source     = "./modules/redis"
  redis_name = "my-redis"
  vote_vpc   = module.network.vote_vpc
  depends_on = [module.api, module.vm, module.network]
}
