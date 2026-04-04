resource "cloudflare_workers_kv_namespace" "portfolio" {
  account_id = var.cloudflare_account_id
  title      = "portfolio-kv"
}

resource "cloudflare_workers_custom_domain" "apex" {
  account_id  = var.cloudflare_account_id
  hostname    = var.domain
  service     = "portfolio"
  zone_id     = cloudflare_zone.main.id
  environment = "production"
}

resource "cloudflare_workers_custom_domain" "www" {
  account_id  = var.cloudflare_account_id
  hostname    = "www.${var.domain}"
  service     = "portfolio"
  zone_id     = cloudflare_zone.main.id
  environment = "production"
}
