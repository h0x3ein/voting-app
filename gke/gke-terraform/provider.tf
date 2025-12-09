terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.22"
    }

  }
  backend "gcs" {
    bucket = "my-lab-tfstate-qwiklabs-gcp-02-4c80d5c6dd9a"
    prefix = "vote-app/state"
  }
  required_version = ">= 1.6.0"
}

provider "google" {
  project = var.project_id
  region  = var.region
}
