data "google_secret_manager_secret_version_access" "cloudflare_api_token" {
  secret = "cloudflare-api-token"
}

data "google_secret_manager_secret_version_access" "cloudflare_zone_id" {
  secret = "cloudflare-zone-id"
}

data "google_secret_manager_secret_version_access" "github_token" {
  secret = "github-pat-readonly"
}

data "google_secret_manager_secret_version_access" "google_dkim" {
  secret = "google-dkim-record"
}

locals {
  cloudflare_zone_id = data.google_secret_manager_secret_version_access.cloudflare_zone_id.secret_data
  github_token       = data.google_secret_manager_secret_version_access.github_token.secret_data
  google_dkim_record = data.google_secret_manager_secret_version_access.google_dkim.secret_data
}
