resource "cloudflare_workers_script" "portfolio" {
  account_id  = var.cloudflare_account_id
  script_name = "portfolio"
  main_module = "worker.mjs"
  content     = file("${path.module}/../site/src/worker.mjs")

  compatibility_date  = "2026-04-02"
  compatibility_flags = ["nodejs_compat"]

  bindings = [
    {
      name         = "KV"
      type         = "kv_namespace"
      namespace_id = cloudflare_workers_kv_namespace.portfolio.id
    },
    {
      name = "AI"
      type = "ai"
    },
    {
      name = "GITHUB_USERNAMES"
      type = "plain_text"
      text = "ogormans-deptstack,seanogor"
    },
  ]
}

resource "cloudflare_workers_kv_namespace" "portfolio" {
  account_id = var.cloudflare_account_id
  title      = "portfolio-kv"
}

resource "cloudflare_workers_cron_trigger" "refresh_prs" {
  account_id  = var.cloudflare_account_id
  script_name = cloudflare_workers_script.portfolio.script_name
  schedules = [
    { cron = "0 */6 * * *" }
  ]
}

resource "cloudflare_workers_custom_domain" "apex" {
  account_id = var.cloudflare_account_id
  hostname   = var.domain
  service    = cloudflare_workers_script.portfolio.script_name
  zone_id    = cloudflare_zone.main.id
}

resource "cloudflare_workers_custom_domain" "www" {
  account_id = var.cloudflare_account_id
  hostname   = "www.${var.domain}"
  service    = cloudflare_workers_script.portfolio.script_name
  zone_id    = cloudflare_zone.main.id
}
