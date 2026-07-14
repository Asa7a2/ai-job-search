---
name: gupy-search
version: 1.0.0
description: >
  Use this skill whenever the user wants to search for jobs in Brazil, find Brazilian job
  listings, look up a specific Gupy job posting, or asks about the Brazilian job market —
  even if they don't mention Gupy explicitly. Gupy (gupy.io) is Brazil's largest recruiting
  ATS; this skill searches Portal Gupy, its central aggregator covering every company that
  runs its career site on Gupy, across all sectors and cities. Trigger phrases: vagas Gupy,
  vagas de emprego, vagas no Brasil, buscar vagas, empregos no Brasil, oportunidades de
  emprego, vaga de analista de dados, vaga de engenheiro de dados, Gupy jobs, jobs in
  Brazil, Brazilian jobs, Brazil job search, find a job in Brazil, job openings Brazil,
  "vagas em São Paulo", "trabalho remoto Brasil", look up this Gupy job posting.
context: fork
allowed-tools: Bash(bun run .agents/skills/gupy-search/cli/src/cli.ts *)
---

# Gupy Search Skill

Search live job listings from **Portal Gupy** (`portal.gupy.io`), Gupy's central job
aggregator — Brazil's largest recruiting ATS. It indexes postings from every company that
runs its career site on Gupy, across all sectors and every Brazilian city (plus remote). No
authentication, no API key, and **zero runtime dependencies** — it runs with just `bun`.

## ⚠️ Personal use only

This uses an internal, undocumented Gupy API (the same one `portal.gupy.io`'s own frontend
calls) discovered by reading the site's JS bundles — see `url-reference.md` for how it was
found. Gupy's Terms of Use explicitly prohibit aggregating, copying, or duplicating job
listings via automated means, so **keep volume low and don't use it commercially or for
bulk data collection.** Run it on your own responsibility.

## When to use this skill

- Search for job openings anywhere in Brazil (any city, sector, or role) or remotely
- Filter by recency (posted today / last 7 / 14 / 30 days) or workplace type (remote/hybrid/on-site)
- Get the full description of a specific Gupy job listing, from any of Gupy's URL formats

## Commands

### Search job listings

```bash
bun run .agents/skills/gupy-search/cli/src/cli.ts search [flags]
```

Key flags:
- `--query <text>` / `-q <text>` — keyword search (title, skill, role), e.g. `"Analista de Dados"`. Recommended.
- `--location <text>` / `-l <text>` — city name, e.g. `"São Paulo"`. Maps to Gupy's `city` filter.
- `--jobage <days>` — posted within N days: `1`, `7`, `14`, `30`. Omit for all postings. **Filtered client-side** — Gupy's API has no age parameter (see Notes).
- `--workplaceType <mode>` — `remote`, `hybrid`, or `on-site`.
- `--page <n>` — page number (1-indexed, 10 results per page).
- `--limit <n>` / `-n <n>` — cap total results emitted (client-side).
- `--format json|table|plain` — default `json`.

### Fetch full job detail

```bash
bun run .agents/skills/gupy-search/cli/src/cli.ts detail <id|url> [--format json|plain]
```

`id` is the numeric job ID from `search` results (e.g. `11629415`). You may also pass a
full Gupy job URL in either format Gupy uses: `<company>.gupy.io/jobs/<id>?...` or
`<company>.gupy.io/job/<base64>?...`. Returns the full description, workplace type,
application deadline, and apply link.

## Usage examples

```bash
# Data analyst roles in São Paulo, last 14 days
bun run .agents/skills/gupy-search/cli/src/cli.ts search -q "Analista de Dados" -l "São Paulo" --jobage 14 --format table

# Data engineer roles, fully remote, anywhere in Brazil
bun run .agents/skills/gupy-search/cli/src/cli.ts search -q "Engenheiro de Dados" --workplaceType remote --format table

# BI / Power BI analyst roles, hybrid
bun run .agents/skills/gupy-search/cli/src/cli.ts search -q "Analista BI Power BI" -l "São Paulo" --workplaceType hybrid --format table

# Any role, fully remote across Brazil
bun run .agents/skills/gupy-search/cli/src/cli.ts search -q "dados" --workplaceType remote --jobage 7 --format table

# Full details for a specific job
bun run .agents/skills/gupy-search/cli/src/cli.ts detail 11629415 --format plain

# Full details from a pasted Gupy URL
bun run .agents/skills/gupy-search/cli/src/cli.ts detail "https://caju.gupy.io/job/eyJqb2JJZCI6MTE1NzU5NjUsInNvdXJjZSI6Imd1cHlfcG9ydGFsIn0=?jobBoardSource=gupy_portal" --format plain
```

## Output formats

| Format | Best for |
|--------|----------|
| `json` | Default — programmatic use, passing IDs to `detail` |
| `table` | Quick human-readable scanning |
| `plain` | Reading a single job's full detail (`detail` command) |

All errors are written to **stderr** as `{ "error": "...", "code": "..." }` and the process exits with code `1`.

## Notes

- Data is from `employability-portal.gupy.io/api/v1/jobs` — the internal JSON API behind
  `portal.gupy.io`'s search page. It's not a documented public API; see `url-reference.md`
  for how it was found and what to check first if the markup/endpoint changes.
- Descriptions come back as plain text (no HTML tags to strip), but rich-text editors leave
  stray `&nbsp;`-style entities behind — the CLI decodes those.
- Page size is fixed at 10 results per page, matching the API's own default.
- `--jobage` has no server-side equivalent on this endpoint, so it's applied client-side
  against each result's `publishedDate`. Postings with no date are kept rather than dropped.
- Gupy job IDs are global across the whole platform — an ID found via `search`, or decoded
  from any per-company `<company>.gupy.io` job URL, resolves through the same `detail` call.
- Gupy may rate-limit; the CLI retries 429/5xx with exponential backoff. Keep volume low
  (see ToS note above).
