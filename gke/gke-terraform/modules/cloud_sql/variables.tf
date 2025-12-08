variable "project_id" {
  description = "The project ID"
  type        = string
}

variable "region" {
  description = "Region for the Cloud SQL instance"
  type        = string
}

variable "instance_name" {
  description = "Name of the Cloud SQL instance"
  type        = string
  default     = "voting-app-sql"
}

variable "database_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "POSTGRES_15"
}

variable "tier" {
  description = "Machine type for the instance"
  type        = string
  default     = "db-f1-micro" # Smallest for testing/dev
}

variable "db_name" {
  description = "Name of the database to create"
  type        = string
  default     = "voting-app-db"
}

variable "db_user" {
  description = "Name of the default user"
  type        = string
  default     = "voting-app-user"
}

variable "db_password" {
  description = "Password for the default user"
  type        = string
  sensitive   = true
}

variable "private_network_id" {
  description = "The ID of the VPC network to peer with (usually google_compute_network.vpc.id)"
  type        = string
}
