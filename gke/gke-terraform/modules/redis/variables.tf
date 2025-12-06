variable "project_id" {
  description = "The ID of the project in which the Redis instance will be created."
  type        = string
}

variable "region" {
  description = "The region where the Redis instance will be located (e.g., us-central1)."
  type        = string
}

variable "network_id" {
  description = "The VPC network URI where the peering connection is established."
  type        = string
}

variable "memory_size_gb" {
  description = "The size of the Redis instance memory in GB."
  type        = number
  default     = 1
}

variable "tier" {
  description = "The service tier of the Redis instance (BASIC or STANDARD_HA)."
  type        = string
  default     = "STANDARD_HA"
}