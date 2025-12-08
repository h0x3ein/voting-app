terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.22"
    }

  }
  backend "gcs" {
    bucket = "my-lab-tfstate-qwiklabs-gcp-04-f3b0d79dd5de"
    prefix = "vote-app/state"
  }
  required_version = ">= 1.6.0"
}

provider "google" {
  project = var.project_id
  region  = var.region
}