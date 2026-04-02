terraform {
  required_version = ">= 1.9"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.52"
    }
  }

  backend "gcs" {
    bucket = "gorm-ogham-portfolio-tofu-state"
    prefix = "prod"
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = "us-central1"
}

provider "cloudflare" {
  api_token = data.google_secret_manager_secret_version_access.cloudflare_api_token.secret_data
}
