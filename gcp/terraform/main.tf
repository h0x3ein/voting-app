module "api" {
  source     = "./modules/api"
  project_id = var.project_id
}

module "iam" {
  source     = "./modules/iam"
  project_id = var.project_id
  depends_on = [module.api]
}


module "secrets" {
  source                    = "./modules/secrets"
  project_id                = var.project_id
  mysql_password_value      = var.mysql_password_value
  mysql_root_password_value = var.mysql_root_password_value
  mysql_user_value          = var.mysql_user_value
  depends_on                = [module.api]
}


module "network" {
  source      = "./modules/network"
  project_id  = var.project_id
  region      = var.region
  network_name = "vote-app-vpc"
}

module "vm" {
  source       = "./modules/vm"
  project_id   = var.project_id
  name         = "redis-proxy"
  zone         = var.zone
  network      = module.network.network_self_link
  depends_on       = [module.network]
}

module "redis" {
  source           = "./modules/redis"
  project_id       = var.project_id
  region           = var.region
  redis_name       = "my-redis"
  network_self_link = module.network.network_self_link
  environment      = "dev"
  depends_on       = [module.network]
}


module "cloudsql" {
  source            = "./modules/cloudsql"
  project_id        = var.project_id
  region            = var.region
  network_self_link = module.network.network_self_link
  db_instance_name  = var.db_instance_name
  db_name           = var.db_name
  db_user           = var.mysql_user_value
  db_pass           = var.mysql_password_value
  proxy_sa_name     = var.proxy_sa_name
 # key_rotation_id   = var.key_rotation_id
  depends_on       = [module.network]
}