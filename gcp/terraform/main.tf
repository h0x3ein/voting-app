data "google_project" "current" {
  project_id = var.project_id
}


output "project_details" {
  value = data.google_project.current
}