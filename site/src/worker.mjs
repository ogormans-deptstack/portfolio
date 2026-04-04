const SECURITY_HEADERS = {
  "X-Content-Type-Options": "nosniff",
  "X-Frame-Options": "DENY",
  "Referrer-Policy": "strict-origin-when-cross-origin",
  "Permissions-Policy":
    "camera=(), microphone=(), geolocation=(), interest-cohort=()",
  "Content-Security-Policy":
    "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https://github-readme-stats.vercel.app; font-src 'self' data:; connect-src 'self'",
  "X-DNS-Prefetch-Control": "off",
};

export default {
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

async function handleApi(url, env) {
  const headers = {
    "Content-Type": "application/json",
    "Cache-Control": "public, max-age=3600",
    "Access-Control-Allow-Origin": "*",
  };

  if (url.pathname === "/api/prs") {
    const data = await env.KV.get("github-prs");
    return new Response(data || "[]", { headers });
  }

  if (url.pathname === "/api/merged") {
    const data = await env.KV.get("merged-prs");
    return new Response(data || '{"prs":[]}', { headers });
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
  const h = new Headers(response.headers);
  for (const [k, v] of Object.entries(SECURITY_HEADERS)) {
    h.set(k, v);
  }
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers: h,
  });
}
