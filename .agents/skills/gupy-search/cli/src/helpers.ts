// Data source: Gupy's central "Portal Gupy" job aggregator (https://portal.gupy.io),
// which searches job postings across every company that runs its career site on Gupy
// (Brazil's largest ATS). The public search page is a client-rendered Next.js app; the
// actual data comes from an unauthenticated JSON API discovered by reading the page's
// JS bundles: `employability-portal.gupy.io/api/v1/jobs`. It returns clean JSON (no HTML
// to parse), so this CLI is a thin JSON client rather than a scraper — but see the
// personal-use warning in SKILL.md: Gupy's Terms of Use prohibit aggregating/copying
// job listings via automated means, same restriction class as LinkedIn's ToS.

export const SEARCH_URL = "https://employability-portal.gupy.io/api/v1/jobs"
export const DETAIL_URL = "https://employability-portal.gupy.io/api/v1/jobs"

export function writeError(error: string, code: string): void {
  process.stderr.write(JSON.stringify({ error, code }) + "\n")
}

const UA =
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 " +
  "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

/** Fetch JSON with exponential backoff on 429/5xx. Returns null on a 404. */
export async function jsonFetch<T>(url: string): Promise<T | null> {
  const maxRetries = 6
  let delay = 500
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    const response = await fetch(url, {
      headers: {
        "User-Agent": UA,
        Accept: "application/json",
        Origin: "https://portal.gupy.io",
        Referer: "https://portal.gupy.io/",
      },
      redirect: "follow",
    })
    if (response.status === 429 || response.status >= 500) {
      if (attempt === maxRetries) {
        throw new Error(`Request failed: ${response.status} ${response.statusText}`)
      }
      const jitter = Math.floor(Math.random() * 500)
      await new Promise((r) => setTimeout(r, delay + jitter))
      delay = Math.min(delay * 2, 8000)
      continue
    }
    if (response.status === 404) return null
    if (!response.ok) {
      throw new Error(`Request failed: ${response.status} ${response.statusText}`)
    }
    return (await response.json()) as T
  }
  throw new Error("Request failed after max retries")
}

/** Raw shape of a job object as returned by employability-portal.gupy.io/api/v1/jobs. */
export interface GupyRawJob {
  id: number
  companyId: number
  name: string
  description: string
  careerPageId: number
  careerPageName: string
  careerPageLogo?: string
  careerPageUrl?: string
  type?: string
  publishedDate: string | null
  applicationDeadline?: string | null
  isRemoteWork?: boolean
  city?: string
  state?: string
  country?: string
  jobUrl: string
  workplaceType?: string | null
  disabilities?: boolean
  skills?: string[]
}

export interface GupySearchResponse {
  data: GupyRawJob[]
  pagination: { total: number; limit: number; offset: number }
}

export interface JobCard {
  id: string
  title: string
  company: string | null
  location: string | null
  date: string | null
  url: string
}

export interface JobDetail extends JobCard {
  description: string | null
  workplaceType: string | null
  isRemoteWork: boolean | null
  applicationDeadline: string | null
  jobType: string | null
}

/**
 * Decode the handful of HTML entities that show up in Gupy's plain-text description
 * field (mainly &nbsp; from rich-text editors). The field is not HTML — no tags to
 * strip — but authors' rich-text editors leave entities behind.
 */
export function decodeEntities(text: string): string {
  return text
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&apos;/g, "'")
    .replace(/&nbsp;/g, " ")
}

function locationOf(job: GupyRawJob): string | null {
  if (job.workplaceType === "remote" || job.isRemoteWork) {
    const parts = [job.city, job.state].filter(Boolean)
    return parts.length ? `${parts.join(", ")} (Remoto)` : "Remoto"
  }
  const parts = [job.city, job.state].filter((p) => p && p.length > 0)
  return parts.length ? parts.join(", ") : job.country || null
}

export function toJobCard(job: GupyRawJob): JobCard {
  return {
    id: String(job.id),
    title: job.name ? job.name.trim() : "(untitled)",
    company: job.careerPageName || null,
    location: locationOf(job),
    date: job.publishedDate || null,
    url: job.jobUrl,
  }
}

export function toJobDetail(job: GupyRawJob): JobDetail {
  return {
    ...toJobCard(job),
    description: job.description ? decodeEntities(job.description).trim() || null : null,
    workplaceType: job.workplaceType || null,
    isRemoteWork: typeof job.isRemoteWork === "boolean" ? job.isRemoteWork : null,
    applicationDeadline: job.applicationDeadline || null,
    jobType: job.type || null,
  }
}

/** Accept a raw numeric job ID, a portal `/job/<base64>` URL, or a `/jobs/<id>` URL. */
export function normalizeId(input: string): string | null {
  const bare = input.match(/^\d+$/)
  if (bare) return input

  // <company>.gupy.io/jobs/<id>?... (public job-page URL format)
  const plainPath = input.match(/\/jobs?\/(\d+)(?:[/?]|$)/)
  if (plainPath) return plainPath[1]

  // <company>.gupy.io/job/<base64>?... where base64 decodes to {"jobId":123,...}
  const b64Path = input.match(/\/job\/([A-Za-z0-9+/=_-]+)/)
  if (b64Path) {
    try {
      const decoded = Buffer.from(b64Path[1], "base64").toString("utf8")
      const parsed = JSON.parse(decoded) as { jobId?: number }
      if (parsed.jobId) return String(parsed.jobId)
    } catch {
      // fall through
    }
  }
  return null
}

/** Convert a job-age in days to an ISO cutoff instant, or null for "all time". */
export function jobageToCutoff(days: number): Date | null {
  if (!days || days <= 0 || days >= 9999) return null
  const cutoff = new Date()
  cutoff.setDate(cutoff.getDate() - days)
  return cutoff
}
