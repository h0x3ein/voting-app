module "api" {
  source = "./modules/api"
}

module "iam" {
  source = "./modules/iam"
  project_id = var.project_id
}

module "secretmanager" {
  source = "./modules/secretmanager"
  mysql_root_password = var.mysql_root_password
  mysql_password = var.mysql_password
  mysql_user = var.mysql_user
  depends_on = [ module.api ]
}

