variable "network_self_link" {
  description = "The self-link of the VPC network for private connection."
  type        = string
}

variable "vote_vpc" {
  description = "The name of the Cloud SQL instance."
  type        = string
  default     = "voteapp-mysql"
}

variable "db_tier" {
  description = "The machine tier for the database instance."
  type        = string
  default     = "db-custom-1-3840"
}

variable "db_instance_name" {
  description = "The name of the Cloud SQL instance."
  type        = string
  default     = "voteapp-mysql"
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
