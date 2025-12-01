###############################################
# 🌍 General Settings
###############################################

variable "project_id" {
  description = "The ID of the GCP project."
  type        = string
}

variable "region" {
  description = "The region where resources will be created."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The zone where resource will be created"
}

###############################################
# 💾 Cloud SQL Variables
###############################################

variable "db_instance_name" {
  description = "Cloud SQL instance name."
  type        = string
  default     = "voteapp-sql"
}

variable "db_name" {
  description = "Database name inside the SQL instance."
  type        = string
  default     = "voteapp"
}

#variable "db_user" {
#  description = "MySQL username for the app."
#  type        = string
#  default     = "voteuser"
#}
#
#variable "db_pass" {
#  description = "MySQL password for the app (used for initial DB setup)."
#  type        = string
#  sensitive   = true
#}
#
variable "proxy_sa_name" {
  description = "Service Account name for the Cloud SQL Proxy."
  type        = string
  default     = "cloudsql-proxy"
}

################################################
## 🔐 Secret Manager Variables
################################################

variable "mysql_password_value" {
  description = "The MySQL password to store in Secret Manager."
  type        = string
  sensitive   = true
}

variable "mysql_root_password_value" {
  description = "The MySQL root password to store in Secret Manager."
  type        = string
  sensitive   = true
}

variable "mysql_user_value" {
  description = "The MySQL username to store in Secret Manager."
  type        = string
}
