# Cloudflare CI/CD Architecture Decisions

## Decision: Use Single Cloudflare API Token for All Operations

**Rationale**: Cloudflare's API token can be scoped with multiple permissions, avoiding the need for separate tokens for Terraform, Wrangler, and R2 operations. Simplifies secret management.

**Alternative considered**: Separate tokens for Terraform (zone/DNS), Wrangler (Workers), and R2 (storage)
**Why rejected**: Unnecessary complexity, more secrets to rotate, same security posture

## Decision: GitHub Variables for Account ID

**Rationale**: Account ID is not sensitive (visible in Cloudflare dashboard URLs), storing as a variable instead of secret improves transparency and debugging.

**Alternative considered**: Store as secret
**Why rejected**: Unnecessary encryption overhead, harder to debug workflow issues

## Decision: sed for Runtime Substitution

**Rationale**: Keeps terraform.tf and wrangler.toml with placeholders in git, allowing CI to inject actual values at runtime. Avoids committing account-specific IDs.

**Alternative considered**: Pre-commit substitution or separate files per environment
**Why rejected**: Harder to track changes, risk of committing secrets

## Decision: Inline R2 Bucket Creation in Jobs

**Rationale**: Idempotent wrangler command makes a separate bootstrap job unnecessary, reducing workflow complexity.

**Alternative considered**: Dedicated setup job with dependencies
**Why rejected**: Overkill for single idempotent command

## Decision: workflow_dispatch Trigger Inclusion

**Rationale**: Allows manual deploys from GitHub UI without requiring a push to main, useful for testing or hotfixes.

**Alternative considered**: Only automatic triggers
**Why rejected**: Reduces operational flexibility

## Decision: GitHub Actions as "Recommended" Path

**Rationale**: Eliminates need for users to manage local R2 credentials, simpler onboarding, more secure (secrets in GitHub vault vs local env vars).

**Alternative considered**: Keep local bootstrap.sh as primary path
**Why rejected**: Higher friction, more credentials to manage, harder to audit

## Decision: Keep bootstrap.sh as Optional

**Rationale**: Some users prefer local development workflow, especially during initial experimentation. Script now clearly communicates it's optional.

**Alternative considered**: Remove bootstrap.sh entirely
**Why rejected**: Removes valid use case for local-first developers
