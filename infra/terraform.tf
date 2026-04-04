terraform {
  required_version = ">= 1.9"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.18"
    }
  }

  backend "http" {
    address        = "https://pub-957a71c8739c4f92b9f2d99b0ef04649.r2.dev/portfolio/terraform.tfstate"
    lock_address   = "https://pub-957a71c8739c4f92b9f2d99b0ef04649.r2.dev/portfolio/terraform.tfstate"
    unlock_address = "https://pub-957a71c8739c4f92b9f2d99b0ef04649.r2.dev/portfolio/terraform.tfstate"
  }

  encryption {
    key_provider "pbkdf2" "state_key" {
      passphrase = var.tf_encryption_key
    }

    method "aes_gcm" "state_enc" {
      keys = key_provider.pbkdf2.state_key
    }

    state {
      method = method.aes_gcm.state_enc
      fallback {
        method = method.unencrypted.migration
      }
    }

    method "unencrypted" "migration" {}
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
