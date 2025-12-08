variable "project_id" {
  description = "The ID of the GCP project."
  type        = string
}

variable "instance_name" {
  description = "Name of the Cloud SQL instance (used for SA naming)"
  type        = string
  default     = "voting-app-sql"
}

variable "ksa_name" {
  description = "Name of the Kubernetes Service Account to bind to"
  type        = string
  default     = "default"
}

variable "ksa_namespace" {
  description = "Namespace of the Kubernetes Service Account"
  type        = string
  default     = "default"
}