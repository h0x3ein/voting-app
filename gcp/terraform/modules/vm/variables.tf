variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "name" {
  description = "Name of the VM instance"
  type        = string
}

variable "zone" {
  description = "GCP zone where the VM will be created"
  type        = string
}

variable "machine_type" {
  description = "Machine type (e.g., e2-micro)"
  type        = string
  default     = "e2-micro"
}

variable "image" {
  description = "Image for the VM (e.g., debian-cloud/debian-12)"
  type        = string
  default     = "debian-cloud/debian-12"
}

variable "network" {
  description = "VPC network name or self_link"
  type        = string
}

variable "subnetwork" {
  description = "Subnetwork name (optional)"
  type        = string
  default     = null
}

variable "assign_public_ip" {
  description = "If true, the VM will get a public IP address"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Network tags to apply (for firewall rules)"
  type        = list(string)
  default     = []
}

variable "startup_script" {
  description = "Optional startup script for installing software"
  type        = string
  default     = ""
}

#variable "service_account_email" {
#  description = "Service account email to attach to the VM"
#  type        = string
#  default     = "default"
#}
