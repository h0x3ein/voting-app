variable "region" {
  description = "The region where resources will be created."
  type        = string
}

variable "project_id" {
  description = "The ID of the GCP project."
  type        = string
}

variable "cluster_name" {
  type = string
}

variable "network_id" { type = string }
variable "subnetwork_id" { type = string }

variable "pods_range_name" { type = string }
variable "services_range_name" { type = string }

variable "node_service_account_email" { type = string }

variable "machine_type" { type = string }
variable "disk_size_gb" { type = number }

variable "min_nodes" { type = number }
variable "max_nodes" { type = number }