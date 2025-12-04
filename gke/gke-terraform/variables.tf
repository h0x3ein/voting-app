variable "project_id" {
  description = "The ID of the GCP project."
  type        = string
}

variable "region" {
  description = "The region where resources will be created."
  type        = string
}

variable "cluster_name" {
  type = string
}

variable "machine_type" {
  type        = string
  description = "GKE node machine type"
}

variable "disk_size_gb" {
  type        = number
  description = "Node boot disk size (GB)"
}

variable "min_nodes" {
  type        = number
  description = "Minimum nodes for node pool autoscaling"
}

variable "max_nodes" {
  type        = number
  description = "Maximum nodes for node pool autoscaling"
}