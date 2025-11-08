
variable "project_id" {
  description = "The ID of the GCP project."
  type        = string
}

variable "region" {
  description = "The region where resources will be created."
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