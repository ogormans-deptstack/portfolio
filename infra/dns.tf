resource "cloudflare_zone" "main" {
  account = {
    id = var.cloudflare_account_id
  }
  name = var.domain
  type = "full"
}

locals {
  zone_settings_on = toset([
    "always_use_https",
    "automatic_https_rewrites",
    "brotli",
    "http3",
    "0rtt",
  ])
}

resource "cloudflare_zone_setting" "on" {
  for_each   = local.zone_settings_on
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

resource "cloudflare_dns_record" "google_mx_1" {
  zone_id  = cloudflare_zone.main.id
  name     = "@"
  type     = "MX"
  content  = "aspmx.l.google.com"
  priority = 1
  ttl      = 3600
}

resource "cloudflare_dns_record" "google_mx_2" {
  zone_id  = cloudflare_zone.main.id
  name     = "@"
  type     = "MX"
  content  = "alt1.aspmx.l.google.com"
  priority = 5
  ttl      = 3600
}

resource "cloudflare_dns_record" "google_mx_3" {
  zone_id  = cloudflare_zone.main.id
  name     = "@"
  type     = "MX"
  content  = "alt2.aspmx.l.google.com"
  priority = 5
  ttl      = 3600
}

resource "cloudflare_dns_record" "google_mx_4" {
  zone_id  = cloudflare_zone.main.id
  name     = "@"
  type     = "MX"
  content  = "alt3.aspmx.l.google.com"
  priority = 10
  ttl      = 3600
}

resource "cloudflare_dns_record" "google_mx_5" {
  zone_id  = cloudflare_zone.main.id
  name     = "@"
  type     = "MX"
  content  = "alt4.aspmx.l.google.com"
  priority = 10
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
  content = local.google_dkim_record
  ttl     = 3600
}
