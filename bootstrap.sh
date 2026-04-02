#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="${GCP_PROJECT_ID:?Set GCP_PROJECT_ID}"
REGION="us-central1"
BUCKET_NAME="${PROJECT_ID}-tofu-state"
SA_NAME="tofu-deployer"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
GITHUB_REPO="${GITHUB_REPO:-ogormans-deptstack/portfolio}"
GITHUB_OWNER="${GITHUB_REPO%%/*}"

gcloud config set project "${PROJECT_ID}"

gcloud services enable \
	storage.googleapis.com \
	secretmanager.googleapis.com \
	iam.googleapis.com \
	iamcredentials.googleapis.com \
	cloudresourcemanager.googleapis.com \
	sts.googleapis.com

gcloud storage buckets create "gs://${BUCKET_NAME}" \
	--location="${REGION}" \
	--uniform-bucket-level-access \
	--public-access-prevention 2>/dev/null || echo "Bucket already exists"

gcloud storage buckets update "gs://${BUCKET_NAME}" --versioning

gcloud iam service-accounts create "${SA_NAME}" \
	--display-name="OpenTofu Deployer" 2>/dev/null || echo "SA already exists"

gcloud storage buckets add-iam-policy-binding "gs://${BUCKET_NAME}" \
	--member="serviceAccount:${SA_EMAIL}" \
	--role="roles/storage.objectAdmin" --quiet

gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
	--member="serviceAccount:${SA_EMAIL}" \
	--role="roles/secretmanager.secretAccessor" --quiet

gcloud iam workload-identity-pools create "github" \
	--project="${PROJECT_ID}" \
	--location="global" \
	--display-name="GitHub Actions" 2>/dev/null || echo "WIF pool already exists"

gcloud iam workload-identity-pools providers create-oidc "portfolio-repo" \
	--project="${PROJECT_ID}" \
	--location="global" \
	--workload-identity-pool="github" \
	--display-name="Portfolio Repo" \
	--attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
	--attribute-condition="assertion.repository_owner == '${GITHUB_OWNER}'" \
	--issuer-uri="https://token.actions.githubusercontent.com" 2>/dev/null || echo "WIF provider already exists"

POOL_NAME=$(gcloud iam workload-identity-pools describe "github" \
	--project="${PROJECT_ID}" --location="global" --format="value(name)")

gcloud iam service-accounts add-iam-policy-binding "${SA_EMAIL}" \
	--project="${PROJECT_ID}" \
	--role="roles/iam.workloadIdentityUser" \
	--member="principalSet://iam.googleapis.com/${POOL_NAME}/attribute.repository/${GITHUB_REPO}" --quiet

WIF_PROVIDER=$(gcloud iam workload-identity-pools providers describe "portfolio-repo" \
	--project="${PROJECT_ID}" \
	--location="global" \
	--workload-identity-pool="github" \
	--format="value(name)")

echo ""
echo "=== Bootstrap Complete ==="
echo ""
echo "GCS Bucket:       ${BUCKET_NAME}"
echo "Service Account:  ${SA_EMAIL}"
echo "WIF Provider:     ${WIF_PROVIDER}"
echo ""
echo "Add as GitHub repository variables (Settings > Secrets and variables > Actions > Variables):"
echo "  GCP_PROJECT_ID      = ${PROJECT_ID}"
echo "  GCP_WIF_PROVIDER    = ${WIF_PROVIDER}"
echo "  GCP_SERVICE_ACCOUNT = ${SA_EMAIL}"
echo ""
echo "Next: run ./seed-secrets.sh to populate GCP Secret Manager"
