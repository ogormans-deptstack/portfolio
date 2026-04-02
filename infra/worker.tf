resource "cloudflare_worker_script" "portfolio" {
  account_id = var.cloudflare_account_id
  name       = "portfolio"
  content    = file("${path.module}/../site/src/worker.mjs")
  module     = true

  kv_namespace_binding {
    name         = "KV"
    namespace_id = cloudflare_workers_kv_namespace.portfolio.id
  }

  secret_text_binding {
    name = "GITHUB_TOKEN"
    text = local.github_token
  }

  plain_text_binding {
    name = "GITHUB_USERNAMES"
    text = "ogormans-deptstack,seanogor"
  }
}

resource "cloudflare_workers_kv_namespace" "portfolio" {
  account_id = var.cloudflare_account_id
  title      = "portfolio-kv"
}

resource "cloudflare_worker_cron_trigger" "refresh_prs" {
  account_id  = var.cloudflare_account_id
  script_name = cloudflare_worker_script.portfolio.name
  schedules   = ["0 */6 * * *"]
}

resource "cloudflare_worker_domain" "apex" {
  account_id = var.cloudflare_account_id
  hostname   = var.domain
  service    = cloudflare_worker_script.portfolio.name
  zone_id    = cloudflare_zone.main.id
}

resource "cloudflare_worker_domain" "www" {
  account_id = var.cloudflare_account_id
  hostname   = "www.${var.domain}"
  service    = cloudflare_worker_script.portfolio.name
  zone_id    = cloudflare_zone.main.id
}
