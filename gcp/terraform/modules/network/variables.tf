variable "region" {
  description = "The region where resources will be created."
  type        = string
  default     = "us-central1"
}

variable "project_id" {
  description = "The ID of the GCP project."
  type        = string
}

variable "network_name" {
  description = "The Name of networkName of the VPC network to create or use"
  type        = string
  default     = "vote-app-vpc"
}