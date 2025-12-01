
variable "project_id" {
  description = "The ID of the GCP project."
  type        = string
}

variable "region" {
  description = "The region where resources will be created."
  type        = string
}

variable "zone" {
  description = "Zone where the VM will be created"
  type        = string
}

variable "mysql_root_password" {
  description = "Root password for MySQL"
  type        = string
}

variable "mysql_password" {
  description = "Password for MySQL user"
  type        = string
}

variable "mysql_user" {
  description = "MySQL username"
  type        = string
}

variable "db_name" {
  description = "Database name inside the SQL instance."
  type        = string
}

variable "proxy_sa_name" {
  description = "Service Account name for the Cloud SQL Proxy."
  type        = string
}


variable "db_instance_name" {
  description = "Cloud SQL instance name."
  type        = string
  default     = "voteapp-sql"
}
