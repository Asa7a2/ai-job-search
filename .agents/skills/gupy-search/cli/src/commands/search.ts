import {
  SEARCH_URL,
  jsonFetch,
  toJobCard,
  jobageToCutoff,
  writeError,
  type GupySearchResponse,
  type JobCard,
} from "../helpers.js"

export interface SearchOpts {
  query?: string
  location?: string // maps to Gupy's `city` param
  jobage: number
  workplaceType?: string // "remote" | "hybrid" | "on-site"
  page: number
  limit?: number
  format: "json" | "table" | "plain"
}

const PAGE_SIZE = 10 // matches Gupy's own default page size

function buildUrl(opts: SearchOpts): string {
  const params = new URLSearchParams()
  if (opts.query) params.set("jobName", opts.query)
  if (opts.location) params.set("city", opts.location)
  if (opts.workplaceType) params.set("workplaceType", opts.workplaceType)
  params.set("limit", String(PAGE_SIZE))
  params.set("offset", String((opts.page - 1) * PAGE_SIZE))
  return `${SEARCH_URL}?${params.toString()}`
}

function renderTable(cards: JobCard[]): string {
  if (cards.length === 0) return "No results."
  const rows = cards.map((c) => {
    const title = (c.title || "").slice(0, 42).padEnd(42)
    const company = (c.company || "—").slice(0, 26).padEnd(26)
    const loc = (c.location || "—").slice(0, 24).padEnd(24)
    const date = (c.date || "—").slice(0, 10)
    return `${c.id.padEnd(11)} ${title} ${company} ${loc} ${date}`
  })
  const header =
    "ID".padEnd(11) +
    " " +
    "TITLE".padEnd(42) +
    " " +
    "COMPANY".padEnd(26) +
    " " +
    "LOCATION".padEnd(24) +
    " DATE"
  return [header, "-".repeat(header.length), ...rows].join("\n")
}

export async function runSearch(opts: SearchOpts): Promise<number> {
  try {
    const res = await jsonFetch<GupySearchResponse>(buildUrl(opts))
    let cards = (res?.data ?? []).map(toJobCard)

    const cutoff = jobageToCutoff(opts.jobage)
    if (cutoff) {
      cards = cards.filter((c) => {
        if (!c.date) return true // keep undated postings rather than silently dropping them
        const d = new Date(c.date)
        return !isNaN(d.getTime()) && d >= cutoff
      })
    }

    if (opts.limit !== undefined && opts.limit >= 0) cards = cards.slice(0, opts.limit)

    if (opts.format === "table") {
      process.stdout.write(renderTable(cards) + "\n")
    } else if (opts.format === "plain") {
      process.stdout.write(
        cards
          .map(
            (c) =>
              `${c.title}\n  ${c.company || "—"} · ${c.location || "—"} · ${c.date || "—"}\n  id: ${c.id}\n  ${c.url}`,
          )
          .join("\n\n") + "\n",
      )
    } else {
      process.stdout.write(
        JSON.stringify(
          { meta: { count: cards.length, page: opts.page }, results: cards },
          null,
          2,
        ) + "\n",
      )
    }
    return 0
  } catch (e) {
    writeError(e instanceof Error ? e.message : String(e), "SEARCH_FAILED")
    return 1
  }
}
