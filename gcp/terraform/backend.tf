terraform {
  backend "gcs" {
    bucket = "my-lab-tfstate-qwiklabs-gcp-04-8ddc9823819a"
    prefix = "main/state"
  }
}