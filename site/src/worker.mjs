const FILTERED_REPOS = new Set([
  "ogormans-deptstack/enhancements",
  "dept/gni-drupal-cms",
  "HSEIreland/hse-frontend-react",
]);

const STALE_CUTOFF_DAYS = 365;
const AI_MODEL = "@cf/ibm-granite/granite-4.0-h-micro";

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

    const merged = deduped
      .filter((pr) => pr.state === "merged" && pr.merged)
      .sort((a, b) => new Date(b.merged) - new Date(a.merged));

    if (merged.length > 0 && env.AI) {
      await generateMergedBlurb(merged, env);
    }

    await env.KV.put("merged-prs", JSON.stringify(merged), {
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

async function generateMergedBlurb(merged, env) {
  const fingerprint = merged.map((pr) => pr.url).join("|");
  const cachedFingerprint = await env.KV.get("merged-fingerprint");

  if (fingerprint === cachedFingerprint) return;

  const prSummary = merged
    .slice(0, 10)
    .map((pr) => `- ${pr.repo}: ${pr.title}`)
    .join("\n");

  try {
    const result = await env.AI.run(AI_MODEL, {
      messages: [
        {
          role: "system",
          content:
            "Write a concise 2-3 sentence narrative summarizing open source contributions. " +
            "Use a professional but approachable tone. Mention specific projects by name. " +
            "Do not use bullet points. Do not start with 'I'. Write in third person.",
        },
        {
          role: "user",
          content: `Summarize these merged open source pull requests:\n${prSummary}`,
        },
      ],
    });

    const blurb = result.response || "";
    if (blurb.length > 0) {
      await env.KV.put("merged-blurb", blurb, { expirationTtl: 86400 });
      await env.KV.put("merged-fingerprint", fingerprint, {
        expirationTtl: 86400,
      });
    }
  } catch (e) {
    console.error("AI blurb generation failed:", e.message);
  }
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

  if (url.pathname === "/api/merged") {
    const [prs, blurb] = await Promise.all([
      env.KV.get("merged-prs"),
      env.KV.get("merged-blurb"),
    ]);
    return new Response(
      JSON.stringify({
        prs: JSON.parse(prs || "[]"),
        blurb: blurb || null,
      }),
      {
        headers: {
          "Content-Type": "application/json",
          "Cache-Control": "public, max-age=3600",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
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
