output "kv_namespace_id" {
  value       = cloudflare_workers_kv_namespace.portfolio.id
  description = "KV namespace ID for wrangler.toml [[kv_namespaces]]"
}

output "nameservers" {
  value       = cloudflare_zone.main.name_servers
  description = "Nameservers to configure at the domain registrar"
}

output "site_url" {
  value       = "https://${var.domain}"
  description = "Public URL of the deployed portfolio site"
}

output "worker_name" {
  value       = "portfolio"
  description = "Cloudflare Worker script name (deployed via wrangler)"
}

output "zone_id" {
  value       = cloudflare_zone.main.id
  description = "Cloudflare zone ID for the primary domain"
}
