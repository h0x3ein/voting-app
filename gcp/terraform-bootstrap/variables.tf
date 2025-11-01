variable "region" {
  description = "The region where resources will be created."
  type        = string
  default     = "us-central1"
}

variable "project_id" {
  description = "The ID of the GCP project."
  type        = string
}

variable "tf_bucket_name" {
  description = "The name of the GCS bucket that stores the Terraform state file."
  type        = string
}
