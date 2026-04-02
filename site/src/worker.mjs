const FILTERED_REPOS = new Set([
  "ogormans-deptstack/enhancements",
  "dept/gni-drupal-cms",
  "HSEIreland/hse-frontend-react",
]);

const STALE_CUTOFF_DAYS = 365;

export default {
  async scheduled(controller, env, ctx) {
    const usernames = (env.GITHUB_USERNAMES || "ogormans-deptstack").split(",");
    const allPrs = [];

    for (const username of usernames) {
      const prs = await fetchPrsForUser(username.trim(), env);
      allPrs.push(...prs);
    }

    allPrs.sort((a, b) => new Date(b.updated) - new Date(a.updated));

    const deduped = deduplicateByUrl(allPrs);

    await env.KV.put("github-prs", JSON.stringify(deduped), {
      expirationTtl: 86400,
    });
  },

  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.hostname.startsWith("www.")) {
      return Response.redirect(
        `https://${url.hostname.slice(4)}${url.pathname}${url.search}`,
        301
      );
    }

    if (url.pathname.startsWith("/api/")) {
      return handleApi(url, env);
    }

    const response = await env.ASSETS.fetch(request);
    return addSecurityHeaders(response);
  },
};

async function fetchPrsForUser(username, env) {
  const headers = { "User-Agent": "portfolio-worker" };
  if (env.GITHUB_TOKEN) {
    headers["Authorization"] = `Bearer ${env.GITHUB_TOKEN}`;
  }

  const query = encodeURIComponent(`author:${username} type:pr`);
  const apiUrl = `https://api.github.com/search/issues?q=${query}&sort=updated&order=desc&per_page=20`;

  const res = await fetch(apiUrl, { headers });
  if (!res.ok) return [];

  const data = await res.json();
  const now = Date.now();

  return (data.items || [])
    .map((item) => {
      const repo = item.repository_url.split("/").slice(-2).join("/");
      return {
        title: item.title,
        url: item.html_url,
        repo,
        state: item.pull_request?.merged_at ? "merged" : item.state,
        created: item.created_at,
        updated: item.updated_at,
        merged: item.pull_request?.merged_at || null,
        comments: item.comments,
      };
    })
    .filter((pr) => {
      if (FILTERED_REPOS.has(pr.repo)) return false;
      const age = (now - new Date(pr.updated).getTime()) / 86400000;
      if (pr.state === "open" && age > STALE_CUTOFF_DAYS) return false;
      return true;
    });
}

function deduplicateByUrl(prs) {
  const seen = new Set();
  return prs.filter((pr) => {
    if (seen.has(pr.url)) return false;
    seen.add(pr.url);
    return true;
  });
}

async function handleApi(url, env) {
  if (url.pathname === "/api/prs") {
    const data = await env.KV.get("github-prs");
    return new Response(data || "[]", {
      headers: {
        "Content-Type": "application/json",
        "Cache-Control": "public, max-age=3600",
        "Access-Control-Allow-Origin": "*",
      },
    });
  }

  if (url.pathname === "/api/health") {
    return new Response(JSON.stringify({ status: "ok" }), {
      headers: { "Content-Type": "application/json" },
    });
  }

  return new Response(JSON.stringify({ error: "not found" }), {
    status: 404,
    headers: { "Content-Type": "application/json" },
  });
}

function addSecurityHeaders(response) {
  const headers = new Headers(response.headers);
  headers.set("X-Content-Type-Options", "nosniff");
  headers.set("X-Frame-Options", "DENY");
  headers.set("Referrer-Policy", "strict-origin-when-cross-origin");
  headers.set(
    "Permissions-Policy",
    "camera=(), microphone=(), geolocation=(), interest-cohort=()"
  );
  headers.set(
    "Content-Security-Policy",
    "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https://github-readme-stats.vercel.app; font-src 'self' data:; connect-src 'self'"
  );
  headers.set("X-DNS-Prefetch-Control", "off");

  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}
