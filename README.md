# Portfolio — oghamconsults.cc

**Live Portfolio Site** for Sean O'Gorman (Infrastructure Engineer, Ireland)

- **Domain**: oghamconsults.cc
- **Infrastructure**: 100% Cloudflare (Workers, R2, DNS, AI)
- **IaC**: OpenTofu (Terraform fork)
- **Cost**: $0/month (all on free tiers)

---

## Architecture

```
┌─────────────────────────────────────────┐
│ Cloudflare Workers (Edge)               │
│ ├─ www → apex redirect (301)            │
│ ├─ Static assets (HTML/CSS/JS)          │
│ ├─ /api/prs (live GitHub PR feed)       │
│ ├─ /api/merged (AI-generated timeline)  │
│ └─ Security headers (CSP, HSTS, etc.)   │
└─────────────────────────────────────────┘
         │                  │
         ▼                  ▼
┌──────────────────┐ ┌───────────────────┐
│ KV Store         │ │ Workers AI        │
│ • PR cache       │ │ • IBM Granite     │
│ • AI blurb cache │ │   Micro (1B)      │
│ TTL: 24h         │ │ • 2-3 sentence    │
└──────────────────┘ │   narrative       │
         ▲           └───────────────────┘
         │
┌──────────────────────────────────────────┐
│ Cron Trigger (every 6 hours)             │
│ ├─ Fetch PRs from GitHub API             │
│ ├─ Filter merged contributions           │
│ ├─ Generate AI summary if changed        │
│ └─ Cache in KV                            │
└──────────────────────────────────────────┘
```

**Infrastructure as Code**: Managed via OpenTofu with R2 backend for state storage.

---

## Features

### Portfolio Site
- **Dark industrial theme** with ogham alphabet accents (Irish heritage, minimal)
- **Live OSS contributions** from GitHub (real-time PR feed)
- **AI-generated contribution timeline** (Workers AI summarizes merged PRs)
- **Responsive design** — mobile-first, semantic HTML
- **Security**: CSP, HSTS, X-Frame-Options, Referrer-Policy
- **Performance**: <1KB JavaScript, minified CSS/JS/HTML via Cloudflare

### Ogham Design Elements
- Feather marks (᚛ ᚜) on section headers at 40% opacity
- Fixed left-edge vertical text "SEAN" in ogham at 5% opacity
- Horizontal divider with ogham characters between hero and about sections
- Noto Sans Ogham font (OFL 1.1 licensed)

### Free Tier Usage
- **Cloudflare Workers**: 100K requests/day (actual: <1K)
- **Workers AI**: 10K neurons/day (actual: ~2-3K for 4 cron runs)
- **KV Storage**: 100K reads, 1K writes/day (actual: <100 total)
- **R2 Storage**: 10GB, 1M ops/month (actual: ~50KB state file, <500 ops/month)
- **DNS**: Unlimited

---

## Prerequisites

- [**Cloudflare account**](https://dash.cloudflare.com/sign-up) (free tier)
- [**OpenTofu**](https://opentofu.org/docs/intro/install/) >= 1.9 (or Terraform >= 1.9)
- [**Wrangler CLI**](https://developers.cloudflare.com/workers/wrangler/install-and-update/) >= 3.0
- [**asdf**](https://asdf-vm.com/guide/getting-started.html) (optional, for version management)
- **Node.js** >= 22 (for wrangler)

---

## Quick Start

### 1. Clone & Install

```bash
git clone git@github.com:ogormans-deptstack/portfolio.git
cd portfolio

# Install tool versions (if using asdf)
asdf install

# Install wrangler dependencies
cd site && npm install && cd ..
```

### 2. Bootstrap Cloudflare Infrastructure

Set your Cloudflare Account ID:

```bash
export CLOUDFLARE_ACCOUNT_ID="your-account-id"
# Find at: https://dash.cloudflare.com → Workers & Pages → right sidebar
```

Run the bootstrap script:

```bash
./bootstrap.sh
```

This will:
1. Create R2 bucket `portfolio-tfstate` for Terraform state
2. Guide you to create an R2 API token (scoped to the bucket)
3. Prompt for GitHub PAT (readonly, for PR fetching)
4. Set Worker secret via `wrangler secret put`

**Save the R2 credentials** — you'll need them for Terraform.

### 3. Configure OpenTofu

Copy the example terraform vars:

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and fill in:

```hcl
cloudflare_api_token  = "your-cloudflare-api-token"
cloudflare_account_id = "your-account-id"
google_dkim_record    = "v=DKIM1; k=rsa; p=YOUR_DKIM_KEY"
```

**Get Cloudflare API Token**:
- Dashboard → My Profile → API Tokens → Create Token
- Permissions: `Workers Routes:Edit`, `Workers Scripts:Edit`, `Zone:Edit`, `DNS:Edit`
- Zone Resources: `Include → Specific zone → oghamconsults.cc`

**Get Google DKIM** (if using Google Workspace email):
- admin.google.com → Apps → Gmail → Authenticate email
- Generate new record, copy the `p=` value

**Update backend endpoint** in `terraform.tf`:

```hcl
endpoints = {
  s3 = "https://<YOUR_ACCOUNT_ID>.r2.cloudflarestorage.com"
}
```

Replace `<YOUR_ACCOUNT_ID>` with your actual Cloudflare account ID.

### 4. Deploy Infrastructure

Export R2 credentials from bootstrap:

```bash
export AWS_ACCESS_KEY_ID="your-r2-access-key"
export AWS_SECRET_ACCESS_KEY="your-r2-secret-key"
```

Initialize and apply:

```bash
tofu init
tofu plan
tofu apply
```

This creates:
- Cloudflare zone for your domain
- DNS records (MX, SPF, DMARC, DKIM for Google Workspace email)
- Workers script with KV + AI bindings
- Cron trigger (every 6 hours)
- Custom domains (apex + www)

### 5. Deploy Worker Code

```bash
cd ../site
wrangler deploy
```

**Update KV namespace ID** in `wrangler.toml` after first `tofu apply`:

```toml
[[kv_namespaces]]
binding = "KV"
id = "abc123..."  # Get from: tofu output kv_namespace_id
```

### 6. Update Nameservers

After `tofu apply`, get the Cloudflare nameservers:

```bash
tofu output nameservers
```

Update your domain registrar to point to those nameservers.

**DNS propagation takes 1-48 hours.**

---

## Development

### Local Dev Server

```bash
cd site
wrangler dev
```

Open http://localhost:8787

**Note**: AI binding and cron triggers don't work in local dev. Use `wrangler dev --remote` to test against production bindings.

### Trigger Cron Manually

```bash
wrangler dev --test-scheduled
# In another terminal:
curl "http://localhost:8787/__scheduled?cron=0+*/6+*+*+*"
```

### Check Worker Logs

```bash
wrangler tail
```

---

## Secrets Management

All secrets are managed via Wrangler CLI (NOT in Terraform state):

```bash
# Set individual secret
wrangler secret put GITHUB_TOKEN

# Bulk upload from JSON
cat > secrets.json <<EOF
{
  "GITHUB_TOKEN": "ghp_...",
  "GOOGLE_DKIM_RECORD": "v=DKIM1; k=rsa; p=..."
}
EOF
wrangler secret bulk secrets.json
rm secrets.json

# List secrets (names only, values encrypted)
wrangler secret list

# Delete secret
wrangler secret delete SECRET_NAME
```

**Required secrets**:
- `GITHUB_TOKEN` — Fine-grained PAT with public repo read access (for PR API rate limits)

**Terraform variables** (in `terraform.tfvars`):
- `cloudflare_api_token` — Cloudflare API token
- `google_dkim_record` — Google Workspace DKIM (for DNS record)

---

## File Structure

```
portfolio/
├── infra/                    # OpenTofu infrastructure
│   ├── terraform.tf          # Backend (R2) + providers
│   ├── variables.tf          # Input variables
│   ├── dns.tf                # Cloudflare zone + DNS records
│   ├── worker.tf             # Workers script, KV, cron, domains
│   ├── outputs.tf            # Nameservers, URLs, IDs
│   └── terraform.tfvars      # Secret values (gitignored)
├── site/
│   ├── public/               # Static assets
│   │   ├── index.html        # Portfolio HTML
│   │   ├── style.css         # Dark theme + ogham aesthetics
│   │   ├── 404.html          # Custom 404
│   │   └── fonts/            # Noto Sans Ogham (OFL 1.1)
│   ├── src/
│   │   └── worker.mjs        # Cloudflare Worker (API + cron)
│   ├── wrangler.toml         # Worker config
│   ├── package.json          # wrangler dependency
│   └── .npmrc                # Supply chain hardening
├── bootstrap.sh              # One-command Cloudflare setup
├── Makefile                  # dev, deploy, fmt, validate
└── .tool-versions            # asdf version pins
```

---

## Makefile Commands

```bash
make dev          # Start local dev server (wrangler dev)
make deploy       # Deploy worker (wrangler deploy)
make init         # Initialize tofu backend
make plan         # Run tofu plan
make apply        # Run tofu apply
make fmt          # Format all terraform files
make validate     # Validate terraform config
make bootstrap    # Run bootstrap script
```

---

## Cost Breakdown

| Service | Free Tier | Usage | Cost |
|---------|-----------|-------|------|
| **Cloudflare Workers** | 100K req/day | ~500/day | $0 |
| **Workers AI** | 10K neurons/day | ~2-3K/day | $0 |
| **KV Storage** | 100K reads, 1K writes/day | <100 total | $0 |
| **R2 Storage** | 10GB, 1M ops/month | 50KB, <500 ops | $0 |
| **DNS** | Unlimited | 9 records | $0 |
| **Total** | | | **$0/month** |

**No credit card required** for any Cloudflare free tier service.

---

## AI Blurb Generation

Every 6 hours, the Worker:
1. Fetches PRs from GitHub API (both `ogormans-deptstack` and `seanogor` accounts)
2. Filters to merged PRs only, sorted by merge date
3. Generates a fingerprint (URL hash) to detect changes
4. If changed, calls Workers AI with IBM Granite Micro (1B params)
5. Caches the 2-3 sentence narrative in KV

**Model**: `@cf/ibm-granite/granite-4.0-h-micro` (cheapest LLM, 1,542 neurons/M input tokens)

**Prompt**:
```
System: Write a concise 2-3 sentence narrative summarizing open source contributions.
        Use a professional but approachable tone. Mention specific projects by name.
        Do not use bullet points. Do not start with 'I'. Write in third person.

User: Summarize these merged open source pull requests:
      - kubernetes/kubernetes: kubectl explain --example
      - opentofu/opentofu: Pretty-print local state
      ...
```

**Cost**: ~2-3K neurons/day (4 cron runs × ~500-700 neurons/call) = **well within 10K free tier**

---

## DNS Records (Google Workspace Email)

If using Google Workspace for email (`contact@oghamconsults.cc`), the terraform config includes:

- **MX records** (5 servers, priority 1/5/10)
- **SPF**: `v=spf1 include:_spf.google.com ~all`
- **DMARC**: `v=DMARC1; p=quarantine; rua=mailto:dmarc@oghamconsults.cc`
- **DKIM**: `google._domainkey` TXT record (from `var.google_dkim_record`)

**To get DKIM**:
1. admin.google.com → Apps → Gmail → Authenticate email
2. Generate new record for your domain
3. Copy the `v=DKIM1; k=rsa; p=...` value to `terraform.tfvars`

---

## GitHub Actions CI/CD (Optional)

The repo includes `.github/workflows/deploy.yml` for automated deployments, but it's **commented out by default** (requires GitHub secrets setup).

To enable:
1. Uncomment the workflow file
2. Add repository secrets:
   - `CLOUDFLARE_API_TOKEN`
   - `CLOUDFLARE_ACCOUNT_ID`
   - `R2_ACCESS_KEY_ID`
   - `R2_SECRET_ACCESS_KEY`
3. Push to `main` branch → auto-deploy

---

## Troubleshooting

### `tofu init` fails with "NoSuchKey"

**Cause**: OpenTofu can't find the R2 bucket or endpoint is wrong.

**Fix**:
1. Verify bucket exists: `wrangler r2 bucket list`
2. Check `terraform.tf` endpoint matches your account ID: `https://<ACCOUNT_ID>.r2.cloudflarestorage.com`
3. Verify R2 credentials: `echo $AWS_ACCESS_KEY_ID` and `$AWS_SECRET_ACCESS_KEY`

### Worker deployment fails with "KV namespace not found"

**Cause**: `wrangler.toml` references a KV namespace ID that doesn't exist yet.

**Fix**:
1. Run `tofu apply` first to create the namespace
2. Get the ID: `tofu output kv_namespace_id`
3. Update `site/wrangler.toml` with the actual ID
4. Run `wrangler deploy`

### AI blurb not generating

**Cause**: AI binding not configured or cron not running.

**Fix**:
1. Check `tofu apply` created the AI binding: `tofu state show cloudflare_workers_script.portfolio`
2. Manually trigger cron: `wrangler dev --test-scheduled` → `curl "http://localhost:8787/__scheduled"`
3. Check logs: `wrangler tail`

### Domain not resolving

**Cause**: DNS propagation in progress or nameservers not updated.

**Fix**:
1. Check nameservers at registrar match `tofu output nameservers`
2. Wait 1-48 hours for propagation
3. Test with `dig oghamconsults.cc NS` — should return Cloudflare nameservers

---

## License

- **Code**: MIT (portfolio code)
- **Font**: OFL 1.1 (Noto Sans Ogham)
- **Infrastructure**: Infrastructure code is specific to this deployment

---

## Credits

- **Ogham font**: [Noto Sans Ogham](https://github.com/notofonts/ogham) by Google Fonts
- **Workers AI**: [IBM Granite Micro](https://www.ibm.com/granite) (1B parameter LLM)
- **Infrastructure**: Cloudflare Workers, R2, KV, DNS, AI
- **IaC**: OpenTofu (Terraform fork)

---

**Questions?** Open an issue or email contact@oghamconsults.cc
