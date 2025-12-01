variable "name" {
  description = "Name of the VM instance"
  type        = string
}

variable "zone" {
  description = "Zone where the VM will be created"
  type        = string
}

variable "machine_type" {
  description = "Machine type (e.g., e2-micro)"
  type        = string
  default     = "e2-micro"
}

variable "image" {
  description = "Boot image (e.g., debian-cloud/debian-12)"
  type        = string
  default     = "debian-cloud/debian-12"
}

variable "network" {
  description = "Self-link of the VPC network"
  type        = string
}

variable "tags" {
  description = "Additional network tags for the VM"
  type        = list(string)
  default     = []
}
