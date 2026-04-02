output "nameservers" {
  value       = cloudflare_zone.main.name_servers
  description = "Set these as nameservers in Google Cloud Domains"
}

output "zone_id" {
  value = cloudflare_zone.main.id
}

output "worker_name" {
  value = cloudflare_worker_script.portfolio.name
}

output "site_url" {
  value = "https://${var.domain}"
}

output "kv_namespace_id" {
  value       = cloudflare_workers_kv_namespace.portfolio.id
  description = "Set this as 'id' in wrangler.toml [[kv_namespaces]]"
}
