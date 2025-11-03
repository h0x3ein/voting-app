###############################################
# 🔧 Variables for Cloud SQL (MySQL)
###############################################

variable "project_id" {
  description = "The GCP project where Cloud SQL will be deployed."
  type        = string
}

variable "region" {
  description = "Region where the Cloud SQL instance will be created."
  type        = string
  default     = "us-central1"
}

variable "network_self_link" {
  description = "The self-link of the VPC network for private connection."
  type        = string
}

variable "db_instance_name" {
  description = "The name of the Cloud SQL instance."
  type        = string
  default     = "voteapp-mysql"
}

variable "db_tier" {
  description = "The machine tier for the database instance."
  type        = string
  default     = "db-custom-1-3840"
}

variable "db_name" {
  description = "Name of the database to create inside the instance."
  type        = string
  default     = "voteapp"
}

variable "db_user" {
  description = "The MySQL username for the app."
  type        = string
  default     = "voteuser"
}

variable "db_pass" {
  description = "The password for the MySQL user."
  type        = string
}

variable "proxy_sa_name" {
  description = "Name of the service account for Cloud SQL Proxy."
  type        = string
  default     = "cloudsql-proxy"
}

variable "key_rotation_id" {
  description = "Used to force key rotation (change to rotate key)."
  type        = string
  default     = "v1"
}