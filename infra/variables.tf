variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}

variable "cloudflare_account_id" {
  type = string
}

variable "domain" {
  type    = string
  default = "oghamconsults.cc"
}

variable "google_dkim_record" {
  type        = string
  sensitive   = true
  description = "Google Workspace DKIM record from admin.google.com"
}

variable "tf_encryption_key" {
  type        = string
  sensitive   = true
  description = "Passphrase for OpenTofu state encryption (generate with: openssl rand -base64 32)"
}
