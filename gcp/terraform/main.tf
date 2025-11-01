module "iam" {
  source = "./modules/iam"
  project_id = var.project_id
}

module "secret" {
  source = "./modules/secrets"
  project_id = var.project_id
}