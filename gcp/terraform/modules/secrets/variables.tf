###############################################
# 🔧 Variables for Secret Manager Module
###############################################

variable "project_id" {
  description = "The ID of the GCP project where secrets will be created."
  type        = string
}

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