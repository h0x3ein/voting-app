#######################################
# 🔧 Redis Module Variables
#######################################

variable "project_id" {
  description = "The ID of the GCP project where Redis will be created."
  type        = string
}

variable "region" {
  description = "The region to deploy the Redis instance in."
  type        = string
}

variable "redis_name" {
  description = "The name of the Redis instance."
  type        = string
  default     = "my-redis"
}

variable "redis_tier" {
  description = "The service tier for Redis (BASIC or STANDARD_HA)."
  type        = string
  default     = "STANDARD_HA"
}

variable "redis_size_gb" {
  description = "The memory size for the Redis instance in GB."
  type        = number
  default     = 1
}

variable "network_self_link" {
  description = "The self link of the VPC network where Redis will connect."
  type        = string
}

variable "environment" {
  description = "Environment label (e.g., dev, prod)."
  type        = string
  default     = "dev"
}
