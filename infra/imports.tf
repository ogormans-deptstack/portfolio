# Imported resources — kept as documentation of ClickOps resources
# brought under OpenTofu management. Safe to leave in place; tofu
# silently skips import blocks for resources already in state.
#
# Zone: created manually in Cloudflare dashboard on 2026-04-04
# KV namespace: created by a failed tofu apply on 2026-04-04

import {
  to = cloudflare_zone.main
  id = "d1d9da6bf7e3735224263065baa59d62"
}

import {
  to = cloudflare_workers_kv_namespace.portfolio
  id = "57e06258dd3ee22859a3f5fa6508f696/4135f9c4aded4ab78eee5fe303130d47"
}
