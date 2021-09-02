terraform {
  required_version = "~> 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~>3.62.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.1.0"
    }
  }

  backend "gcs" {
    prefix      = "minecraft/state"
    bucket      = "minecraft-permafrost-tf"
    credentials = "credentials.json"
  }

}

provider "google" {
  project     = var.project
  region      = var.region
  zone        = var.zone
  credentials = "credentials.json"
}
