import {
  to = cloudflare_zone.main
  id = "d1d9da6bf7e3735224263065baa59d62"
}

resource "cloudflare_zone" "main" {
  account = {
    id = var.cloudflare_account_id
  }
  name = var.domain
  type = "full"
}
locals {
  enabled_zone_settings = toset([
    "always_use_https",
    "automatic_https_rewrites",
    "brotli",
    "http3",
    "0rtt",
  ])

  google_mx_records = {
    "aspmx.l.google.com"      = 1
    "alt1.aspmx.l.google.com" = 5
    "alt2.aspmx.l.google.com" = 5
    "alt3.aspmx.l.google.com" = 10
    "alt4.aspmx.l.google.com" = 10
  }
}

resource "cloudflare_zone_setting" "enabled_features" {
  for_each   = local.enabled_zone_settings
  zone_id    = cloudflare_zone.main.id
  setting_id = each.key
  value      = "on"
}

resource "cloudflare_zone_setting" "ssl" {
  zone_id    = cloudflare_zone.main.id
  setting_id = "ssl"
  value      = "full"
}

resource "cloudflare_zone_setting" "min_tls_version" {
  zone_id    = cloudflare_zone.main.id
  setting_id = "min_tls_version"
  value      = "1.2"
}

resource "cloudflare_zone_setting" "minify" {
  zone_id    = cloudflare_zone.main.id
  setting_id = "minify"
  value = {
    css  = "on"
    js   = "on"
    html = "on"
  }
}

resource "cloudflare_zone_setting" "security_header" {
  zone_id    = cloudflare_zone.main.id
  setting_id = "security_header"
  value = {
    strict_transport_security = {
      enabled            = true
      include_subdomains = true
      max_age            = 31536000
      nosniff            = true
      preload            = true
    }
  }
}
resource "cloudflare_dns_record" "google_mx" {
  for_each = local.google_mx_records
  zone_id  = cloudflare_zone.main.id
  name     = "@"
  type     = "MX"
  content  = each.key
  priority = each.value
  ttl      = 3600
}

resource "cloudflare_dns_record" "spf" {
  zone_id = cloudflare_zone.main.id
  name    = "@"
  type    = "TXT"
  content = "v=spf1 include:_spf.google.com ~all"
  ttl     = 3600
}

resource "cloudflare_dns_record" "dmarc" {
  zone_id = cloudflare_zone.main.id
  name    = "_dmarc"
  type    = "TXT"
  content = "v=DMARC1; p=quarantine; rua=mailto:dmarc@${var.domain}"
  ttl     = 3600
}

resource "cloudflare_dns_record" "google_dkim" {
  zone_id = cloudflare_zone.main.id
  name    = "google._domainkey"
  type    = "TXT"
  content = var.google_dkim_record
  ttl     = 3600
}
