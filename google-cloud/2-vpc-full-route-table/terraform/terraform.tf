terraform {
  required_version = "0.13.5"

  required_providers {
    google      = "3.46.0"
    google-beta = "3.46.0"
  }

  # The storage bucket needs to be created before it can be used here in the backend
  # backend "gcs" {
  #   bucket = "esdlc-tf-prod-bootstrap-n312-terraform-state"
  #   prefix = "gcp-terraform-network/vpcs/neustar-lz"
  # }
}