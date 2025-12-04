variable "network_name" {
  type    = string
  default = "vote-vpc"
}

variable "project_id" { type = string }
variable "region" { type = string }

variable "subnet_name" {
  type    = string
  default = "vote-subnet"
}

variable "subnet_primary_cidr" {
  type    = string
  default = "10.10.0.0/20"
}

variable "pods_secondary_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "services_secondary_cidr" {
  type    = string
  default = "10.30.0.0/20"
}


variable "pods_range_name" {
  type    = string
  default = "pods-range"
}

variable "services_range_name" {
  type    = string
  default = "services-range"
}