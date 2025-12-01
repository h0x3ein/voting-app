variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The region where resources will be created"
  type        = string
}

variable "network_name" {
  description = "The name of the VPC network to create or use"
  type        = string
  default     = "vote-app-vpc"
}
