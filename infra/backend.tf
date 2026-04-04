terraform {
  backend "s3" {
    bucket = "portfolio-tfstate"
    key    = "portfolio/terraform.tfstate"
    region = "auto"

    endpoints = {
      s3 = "https://57e06258dd3ee22859a3f5fa6508f696.r2.cloudflarestorage.com"
    }

    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
  }
}
