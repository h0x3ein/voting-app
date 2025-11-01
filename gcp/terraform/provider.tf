terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.22"
    }
  }
  required_version = ">= 1.6.0"
}

provider "google" {
  project     = var.project_id
  region      = var.region
}