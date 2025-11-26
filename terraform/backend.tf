terraform {
  backend "gcs" {
    bucket = "jobzy-terraform-state-prod"
    prefix = "jobzy/prod"
  }
}
