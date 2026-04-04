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
}

encryption {
  method {
    aes_gcm {
      keys = key_provider.passphrase.key
    }
  }

  key_provider "passphrase" "key" {
    passphrase = env("TF_ENCRYPTION_KEY")
  }

  state {
    enforced = true
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
