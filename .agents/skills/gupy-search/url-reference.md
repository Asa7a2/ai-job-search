# Gupy (Portal Gupy) URL Reference

Gupy (gupy.io) is Brazil's largest recruiting ATS. Companies get a career subdomain
(`<company>.gupy.io`) for their own postings, and Gupy also runs a central aggregator,
**Portal Gupy** (`https://portal.gupy.io`), that searches across every company's postings
at once. This skill uses the aggregator, because it needs no per-company knowledge and its
job IDs are the same IDs used everywhere else on the platform (including on the per-company
detail pages), so `detail` also works for a job ID found any other way.

> Personal use only — see the ToS note below and in `SKILL.md`.

## How this was found (Step 2 investigation)

`portal.gupy.io` is a client-rendered Next.js app; the search results page
(`/job-search/term=<query>`) does **not** embed results in its server-rendered HTML — it
fetches them client-side after hydration. Reading the page's JS chunks
(`_next/static/chunks/...`) turned up the axios client construction:

```js
o().create({ baseURL: "https://employability-portal.gupy.io" })
```

paired with a request builder that renames UI filter keys before sending them:

```js
{term:c, workplaceTypes:d, ...s} = n
u = {jobName:c, limit:r, offset:l, type:t, badge:o(!!e), isPWD:a, workplaceType:d, ...s}
"".concat("/api/v1/jobs", "?").concat(h)
```

i.e. the real, unauthenticated endpoint is `employability-portal.gupy.io/api/v1/jobs`.
This is not a documented public API — it's the same internal API the portal's own frontend
calls — so it may change without notice; this file records the parsing anchors to check
first if it breaks.

## Search

```
GET https://employability-portal.gupy.io/api/v1/jobs
```

| Param | Meaning | Example | Notes |
|-------|---------|---------|-------|
| `jobName` | Free-text query (title/skill/role) | `Analista de Dados` | Maps from CLI's `--query`/`-q` |
| `city` | City filter | `São Paulo` | Maps from CLI's `--location`/`-l`; confirmed to actually filter results (not just cosmetic) |
| `state` | State filter | `São Paulo` | Not exposed as a CLI flag (city covers the common case); available if a future need arises |
| `workplaceType` | Workplace type | `remote` \| `hybrid` \| `on-site` | Maps from CLI's `--workplaceType` |
| `type` | Vacancy type (renamed from UI's `jobTypes`) | — | Not exposed as a CLI flag; Gupy's internal vacancy-type taxonomy (`vacancy_type_effective`, `vacancy_legal_entity`, etc.) isn't user-facing enough to be worth a flag |
| `isPWD` | Filter to PWD-inclusive postings (renamed from UI's `pwd`) | `true` | Not exposed |
| `badge` | "Friendly badge" filter | `true` | Not exposed |
| `limit` | Page size | `10` | CLI fixes this at 10 (the API's own default) |
| `offset` | Pagination offset | `0`, `10`, `20`, … | CLI computes this from `--page` |

No posting-age ("posted within N days") parameter exists on this endpoint — a guess at
`publishedDateFrom` returned `400 Bad Request`. The CLI filters `--jobage` **client-side**
using each result's `publishedDate` field instead.

**Response shape:**

```json
{
  "data": [
    {
      "id": 11629415,
      "companyId": 6109,
      "name": "Analista de Dados Pl. ",
      "description": "plain text, no HTML tags, but with stray &nbsp; entities",
      "careerPageId": 133924,
      "careerPageName": "Nomos - Melhores Investidores",
      "careerPageUrl": "https://nomos.gupy.io/...",
      "type": "vacancy_legal_entity",
      "publishedDate": "2026-07-13T20:37:06.235Z",
      "applicationDeadline": "2026-09-11",
      "isRemoteWork": true,
      "city": "", "state": "", "country": "Brasil",
      "jobUrl": "https://nomos.gupy.io/job/<base64>?jobBoardSource=gupy_portal",
      "workplaceType": "remote",
      "disabilities": false,
      "skills": []
    }
  ],
  "pagination": { "total": 233, "limit": 10, "offset": 0 }
}
```

Quirk: `pagination.total` appears to be capped around 100 once `limit` grows (observed
`limit=50` reporting `total: 100` for a query whose `limit=10` response reported
`total: 233`) — treat `total` as approximate, not authoritative, past the first page or two.

## Detail

```
GET https://employability-portal.gupy.io/api/v1/jobs/<id>
```

Returns a single job object in the exact same shape as one `data[]` entry above — the CLI
reuses the same mapper for both `search` and `detail`. `<id>` is the numeric Gupy job ID,
which is global across the whole platform (not per-company), so any ID found via `search`,
via a `<company>.gupy.io/jobs/<id>` URL, or decoded from a `<company>.gupy.io/job/<base64>`
URL all resolve through this same endpoint.

### Job ID encodings seen in the wild

- Bare numeric ID: `11629415`
- Public job-page URL: `https://<company>.gupy.io/jobs/<id>?jobBoardSource=gupy_public_page`
- Portal-sourced URL: `https://<company>.gupy.io/job/<base64>?jobBoardSource=gupy_portal`,
  where `<base64>` decodes to `{"jobId":<id>,"source":"gupy_portal"}`. Verified against the
  task's example URL: `eyJqb2JJZCI6MTE1NzU5NjUsInNvdXJjZSI6Imd1cHlfcG9ydGFsIn0=` decodes to
  `{"jobId":11575965,"source":"gupy_portal"}`, and `GET .../api/v1/jobs/11575965` returns
  that exact posting.

## Per-company subdomains (investigated, not used)

Each company's `<company>.gupy.io/` homepage is server-rendered with a small `jobs` array
embedded in `__NEXT_DATA__.props.pageProps.jobs` — but only that company's own postings, no
keyword search, and no documented way to filter/paginate via query string on that route
(tried `?jobName=...`, no effect on the SSR payload). The central aggregator API above
covers everything a per-company scrape would, plus keyword search across all companies at
once, so the subdomains weren't worth building a separate path for.

## Access rules (Step 2 checklist)

- `portal.gupy.io/robots.txt`: `Disallow:` empty — allows everything.
- `<company>.gupy.io/robots.txt` (e.g. `caju.gupy.io`): `Allow: /`, `Disallow: /companies`,
  `Disallow: /candidates` — job listings are allowed; not used by this skill anyway.
- `employability-portal.gupy.io/robots.txt`: 404 (no robots.txt), so no explicit exclusion.
- **Gupy's Terms of Use** (`www.gupy.io/termos-de-uso-recrutamento-e-selecao-candidatos`)
  explicitly prohibit "agregar, copiar ou duplicar partes do Gupy Recrutamento e Seleção,
  incluindo oportunidades de trabalho expiradas" (aggregating, copying, or duplicating
  parts of the platform, including job postings). This is the same class of restriction as
  LinkedIn's ToS, which `linkedin-search` already carries a personal-use warning for — this
  skill carries the same warning; see `SKILL.md`.
