terraform {
  backend "gcs" {
    bucket = "my-lab-tfstate"
    prefix = "main/state" 
  }
}