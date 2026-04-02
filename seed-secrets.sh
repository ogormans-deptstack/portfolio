#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="${GCP_PROJECT_ID:?Set GCP_PROJECT_ID}"
gcloud config set project "${PROJECT_ID}"

create_or_update_secret() {
	local name="$1"
	local prompt="$2"

	if [ -n "${3:-}" ]; then
		value="$3"
	else
		read -rsp "${prompt}: " value
		echo ""
	fi

	if gcloud secrets describe "${name}" --project="${PROJECT_ID}" &>/dev/null; then
		echo -n "${value}" | gcloud secrets versions add "${name}" --data-file=- --quiet
		echo "Updated: ${name}"
	else
		echo -n "${value}" | gcloud secrets create "${name}" \
			--replication-policy="automatic" --data-file=- --quiet
		echo "Created: ${name}"
	fi
}

echo "Seeding secrets into GCP Secret Manager for project: ${PROJECT_ID}"
echo "You can also pass values via env vars: CLOUDFLARE_API_TOKEN, CLOUDFLARE_ACCOUNT_ID, etc."
echo ""

create_or_update_secret "cloudflare-api-token" \
	"Cloudflare API token (Workers + DNS + Zone Settings edit)" \
	"${CLOUDFLARE_API_TOKEN:-}"

create_or_update_secret "cloudflare-zone-id" \
	"Cloudflare Zone ID (from dashboard after adding domain)" \
	"${CLOUDFLARE_ZONE_ID:-}"

create_or_update_secret "github-pat-readonly" \
	"GitHub fine-grained PAT (no scopes needed, for public API rate limits)" \
	"${GITHUB_PAT_READONLY:-}"

create_or_update_secret "google-dkim-record" \
	"Google Workspace DKIM (admin.google.com > Gmail > Authenticate email)" \
	"${GOOGLE_DKIM_RECORD:-}"

echo ""
echo "Done. Verify with: gcloud secrets list --project=${PROJECT_ID}"
