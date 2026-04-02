resource "cloudflare_zone" "main" {
  account_id = var.cloudflare_account_id
  zone       = var.domain
  plan       = "free"
}

resource "cloudflare_zone_settings_override" "main" {
  zone_id = cloudflare_zone.main.id

  settings {
    ssl                      = "full"
    always_use_https         = "on"
    min_tls_version          = "1.2"
    automatic_https_rewrites = "on"
    http3                    = "on"
    zero_rtt                 = "on"
    brotli                   = "on"
    minify {
      css  = "on"
      js   = "on"
      html = "on"
    }
    security_header {
      enabled            = true
      include_subdomains = true
      max_age            = 31536000
      nosniff            = true
      preload            = true
    }
  }
}

resource "cloudflare_record" "google_mx_1" {
  zone_id  = cloudflare_zone.main.id
  name     = "@"
  type     = "MX"
  content  = "aspmx.l.google.com"
  priority = 1
  ttl      = 3600
}

resource "cloudflare_record" "google_mx_2" {
  zone_id  = cloudflare_zone.main.id
  name     = "@"
  type     = "MX"
  content  = "alt1.aspmx.l.google.com"
  priority = 5
  ttl      = 3600
}

resource "cloudflare_record" "google_mx_3" {
  zone_id  = cloudflare_zone.main.id
  name     = "@"
  type     = "MX"
  content  = "alt2.aspmx.l.google.com"
  priority = 5
  ttl      = 3600
}

resource "cloudflare_record" "google_mx_4" {
  zone_id  = cloudflare_zone.main.id
  name     = "@"
  type     = "MX"
  content  = "alt3.aspmx.l.google.com"
  priority = 10
  ttl      = 3600
}

resource "cloudflare_record" "google_mx_5" {
  zone_id  = cloudflare_zone.main.id
  name     = "@"
  type     = "MX"
  content  = "alt4.aspmx.l.google.com"
  priority = 10
  ttl      = 3600
}

resource "cloudflare_record" "spf" {
  zone_id = cloudflare_zone.main.id
  name    = "@"
  type    = "TXT"
  content = "v=spf1 include:_spf.google.com ~all"
  ttl     = 3600
}

resource "cloudflare_record" "dmarc" {
  zone_id = cloudflare_zone.main.id
  name    = "_dmarc"
  type    = "TXT"
  content = "v=DMARC1; p=quarantine; rua=mailto:dmarc@${var.domain}"
  ttl     = 3600
}

resource "cloudflare_record" "google_dkim" {
  zone_id = cloudflare_zone.main.id
  name    = "google._domainkey"
  type    = "TXT"
  content = local.google_dkim_record
  ttl     = 3600
}
