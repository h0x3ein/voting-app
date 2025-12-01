variable "redis_name" {
  description = "The name of the Redis instance."
  type        = string
}

variable "redis_size_gb" {
  description = "The memory size for the Redis instance in GB."
  type        = number
  default     = 1
}

variable "vote_vpc" {
  description = "The self link of the VPC network where Redis will connect."
  type        = string
}