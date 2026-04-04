# Cloudflare CI/CD Migration Learnings

## Workflow Design

### R2 Bucket Creation
- Use idempotent approach: `npx wrangler r2 bucket create <name> 2>/dev/null || echo "Bucket exists"`
- No need for separate bootstrap job - inline in both plan and deploy jobs
- Wrangler CLI handles all R2 operations via CLOUDFLARE_API_TOKEN

### Terraform Backend Configuration
- Backend endpoint must be substituted at runtime: `sed -i 's|<ACCOUNT_ID>|${{ vars.CLOUDFLARE_ACCOUNT_ID }}|g' terraform.tf`
- Keep `<ACCOUNT_ID>` placeholder in committed terraform.tf for easy sed replacement
- R2 credentials passed as AWS_* env vars (R2 is S3-compatible)

### KV Namespace ID Injection
- Extract from Terraform: `tofu output -raw kv_namespace_id`
- Store in GitHub Actions output variable for later steps
- Use sed to replace placeholder comment in wrangler.toml: `sed -i 's/# KV_NAMESPACE_ID.*/id = "..."/' wrangler.toml`

### Worker Secrets
- Use piped input for non-interactive secret setting: `echo "$SECRET" | wrangler secret put SECRET_NAME`
- Requires CLOUDFLARE_API_TOKEN and CLOUDFLARE_ACCOUNT_ID env vars

## GitHub Actions Patterns

### Job Triggers
- PR job: `if: github.event_name == 'pull_request'`
- Deploy job: `if: github.event_name == 'push' && github.ref == 'refs/heads/main' || github.event_name == 'workflow_dispatch'`
- workflow_dispatch allows manual triggers

### Permissions
- Only need `contents: read` and `pull-requests: write`
- No id-token write needed (no OIDC/Workload Identity)

### Secrets vs Variables
- **Secrets**: API tokens, credentials (encrypted)
- **Variables**: Non-sensitive config like account IDs (plaintext)

## Documentation Strategy

### README Structure
1. GitHub Actions section FIRST (recommended path)
2. Local development section SECOND (optional path)
3. Remove old "GitHub Actions (Optional)" stub
4. Detailed credential acquisition steps with direct dashboard links

### bootstrap.sh Messaging
- Add interactive prompt explaining GitHub Actions alternative
- Allow user to abort if they prefer CI/CD
- Clear "(Optional - For Local Development)" in script header

## Cloudflare API Token Requirements

Single token can handle:
- Terraform provider authentication
- Wrangler CLI operations
- R2 bucket creation
- Worker deployment
- KV namespace operations
- Secret management

Required permissions:
- Workers Routes:Edit
- Workers Scripts:Edit
- Workers KV Storage:Edit
- Zone:Edit
- DNS:Edit

## Cost Optimization

- No GitHub Actions minutes consumed for R2 operations (wrangler CLI is fast)
- tofu init/plan/apply typically <2 minutes
- Worker deployment <30 seconds
- Total workflow time: ~3-4 minutes
- Fits comfortably in GitHub free tier (2000 min/month)
