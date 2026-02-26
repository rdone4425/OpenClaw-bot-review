import { NextResponse } from "next/server";

const REPO = process.env.OPENCLAW_REPO || "openclaw/openclaw";

// Server-side cache: 24h TTL
let cache: { data: any; ts: number } | null = null;
const CACHE_TTL = 24 * 60 * 60 * 1000;

async function fetchLatestRelease() {
  const res = await fetch(`https://api.github.com/repos/${REPO}/releases/latest`, {
    headers: {
      Accept: "application/vnd.github+json",
      ...(process.env.GITHUB_TOKEN ? { Authorization: `Bearer ${process.env.GITHUB_TOKEN}` } : {}),
    },
    next: { revalidate: 86400 },
  });
  if (!res.ok) throw new Error(`GitHub API ${res.status}`);
  const data = await res.json();
  return {
    tag: data.tag_name,
    name: data.name || data.tag_name,
    publishedAt: data.published_at,
    body: data.body || "",
    htmlUrl: data.html_url,
  };
}

export async function GET() {
  try {
    if (cache && Date.now() - cache.ts < CACHE_TTL) {
      return NextResponse.json(cache.data);
    }
    const data = await fetchLatestRelease();
    cache = { data, ts: Date.now() };
    return NextResponse.json(data);
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}
