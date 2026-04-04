variable "cloudflare_account_id" {
  type        = string
  description = "Cloudflare account ID"
}

variable "cloudflare_api_token" {
  type        = string
  sensitive   = true
  description = "Cloudflare API token with Zone, DNS, Workers, and KV permissions"
}

variable "domain" {
  type        = string
  default     = "oghamconsults.cc"
  description = "Primary domain for the Cloudflare zone"
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
