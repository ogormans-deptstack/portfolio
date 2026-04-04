terraform {
  required_version = ">= 1.9"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.18"
    }
  }

  encryption {
    key_provider "pbkdf2" "state_key" {
      passphrase = var.tf_encryption_key
    }

    method "aes_gcm" "state_enc" {
      keys = key_provider.pbkdf2.state_key
    }

    state {
      method   = method.aes_gcm.state_enc
      enforced = true
    }
  }
}
