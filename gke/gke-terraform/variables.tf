variable "project_id" {
  description = "The ID of the GCP project."
  type        = string
}

variable "region" {
  description = "The region where resources will be created."
  type        = string
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
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

variable "db_password" {
  description = "The password for the Cloud SQL database user"
  type        = string
  sensitive   = true
}

variable "instance_name" {
  description = "Name of the Cloud SQL instance (used for SA naming)"
  type        = string
  default     = "voting-app-sql"
}

variable "ksa_name" {
  description = "Name of the Kubernetes Service Account for Workload Identity"
  type        = string
  default     = "voting-sa"
}

variable "ksa_namespace" {
  description = "Namespace of the Kubernetes Service Account"
  type        = string
  default     = "vote-app"
}