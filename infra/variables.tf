variable "gcp_project_id" {
  type = string
}

variable "cloudflare_account_id" {
  type = string
}

variable "domain" {
  type    = string
  default = "gorm-ogham-consulting-webhook.com"
}
