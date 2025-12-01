terraform {
  backend "gcs" {
    bucket = "my-lab-tfstate-qwiklabs-gcp-00-d497181e326b"
    prefix = "main/state"
  }
}