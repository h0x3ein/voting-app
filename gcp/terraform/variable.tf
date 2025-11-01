variable "project_id" {
  description = "The GCP project ID where resources will be deployed"
  type        = string
}

variable "region" {
  description = "The GCP region for resource deployment"
  type        = string
  default     = "us-central1"
}