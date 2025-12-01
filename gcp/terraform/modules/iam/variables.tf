variable "project_id" {
  description = "The ID of the GCP project."
  type        = string
}

variable "service_account_name" {
  description = "The name (account_id) of the ESO service account."
  type        = string
  default     = "eso-sa"
}

variable "proxy_sa_name" {
  description = "The service account name for the Cloud SQL Proxy"
  type        = string
  default     = "cloudsql-proxy"
}