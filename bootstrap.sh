#!/usr/bin/env bash
set -euo pipefail

echo "=== Cloudflare Portfolio Bootstrap (Optional - For Local Development) ==="
echo ""
echo "NOTE: If using GitHub Actions, you don't need to run this script."
echo "      CI/CD handles all infrastructure setup automatically."
echo "      See README 'GitHub Actions Deployment' section for setup."
echo ""
read -p "Continue with local setup? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
	echo "Exiting. Use GitHub Actions for automated deployment."
	exit 0
fi
echo ""

ACCOUNT_ID="${CLOUDFLARE_ACCOUNT_ID:?Set CLOUDFLARE_ACCOUNT_ID}"
BUCKET_NAME="portfolio-tfstate"

echo "=== Local Cloudflare Setup ==="
echo ""

echo "[1/2] Creating R2 bucket for Terraform state..."
wrangler r2 bucket create "${BUCKET_NAME}" 2>/dev/null || echo "  → Bucket already exists"

echo ""
echo "[2/2] Create R2 API Token:"
echo "  1. Go to: https://dash.cloudflare.com/${ACCOUNT_ID}/r2/api-tokens"
echo "  2. Click 'Create API Token'"
echo "  3. Permissions: Object Read & Write"
echo "  4. Scope: Apply to specific buckets only → ${BUCKET_NAME}"
echo "  5. Copy Access Key ID and Secret Access Key"
echo ""
read -p "Press Enter when you have the R2 credentials ready..."

read -p "R2 Access Key ID: " R2_ACCESS_KEY
read -sp "R2 Secret Access Key: " R2_SECRET_KEY
echo ""

echo ""
echo "Setting Worker secret (GITHUB_TOKEN)..."
read -sp "GitHub Personal Access Token (readonly, public repo): " GITHUB_TOKEN
echo ""

echo "${GITHUB_TOKEN}" | wrangler secret put GITHUB_TOKEN

echo ""
echo "=== Bootstrap Complete ==="
echo ""
echo "Export these for Terraform:"
echo "  export AWS_ACCESS_KEY_ID=\"${R2_ACCESS_KEY}\""
echo "  export AWS_SECRET_ACCESS_KEY=\"${R2_SECRET_KEY}\""
echo ""
echo "Copy infra/terraform.tfvars.example to infra/terraform.tfvars and fill in:"
echo "  - cloudflare_api_token (from Cloudflare dashboard)"
echo "  - cloudflare_account_id (${ACCOUNT_ID})"
echo "  - google_dkim_record (from admin.google.com > Gmail > Authenticate email)"
echo ""
echo "Update infra/terraform.tf backend endpoint:"
echo "  endpoints = { s3 = \"https://${ACCOUNT_ID}.r2.cloudflarestorage.com\" }"
echo ""
echo "Then run:"
echo "  cd infra && tofu init && tofu plan"
