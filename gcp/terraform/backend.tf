terraform {
  backend "gcs" {
    bucket = "my-lab-tfstate-qwiklabs-gcp-03-7e6718be4914"
    prefix = "main/state"
  }
}