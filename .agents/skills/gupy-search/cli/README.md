# gupy-cli

CLI for searching jobs on **Portal Gupy**, Gupy's central job aggregator that indexes
postings from every company running its career site on Gupy — Brazil's largest ATS.
Covers all sectors and cities across Brazil.

**Data source**: `employability-portal.gupy.io/api/v1/jobs` — an unauthenticated JSON API
that backs the `portal.gupy.io` search page (found by reading the page's JS bundles; it is
not a documented public API).
**Authentication**: None required.
**Dependencies**: None (plain `bun` + `fetch`). `bun install` is optional and only pulls dev type defs.

> **Personal use only.** Gupy's Terms of Use prohibit aggregating, copying, or duplicating
> job listings via automated means. Keep volume low, don't use it commercially or for bulk
> data collection, and run it on your own responsibility.

## Installation

```bash
cd .agents/skills/gupy-search/cli
bun install   # optional — only installs TypeScript dev types
```

The CLI runs without any install because it has zero runtime dependencies.

## Commands

| Command | Description |
|---------|-------------|
| `search` | Search for job listings across all companies on Gupy |
| `detail` | Fetch full detail for a single job listing |

`search` accepts `--format json|table|plain` (default `json`); `detail` accepts `--format json|plain`.
All errors are written to **stderr** as `{ "error": "...", "code": "..." }` with exit code `1`.

## Quick examples

```bash
# Data analyst roles in São Paulo, last 14 days
bun run src/cli.ts search -q "Analista de Dados" -l "São Paulo" --jobage 14 --format table

# Data engineer roles, fully remote
bun run src/cli.ts search -q "Engenheiro de Dados" --workplaceType remote --format table

# Full detail for one job (by numeric ID)
bun run src/cli.ts detail 11629415 --format plain

# Full detail by pasting a Gupy job URL (either URL style Gupy uses)
bun run src/cli.ts detail "https://nomos.gupy.io/job/eyJqb2JJZCI6MTE2Mjk0MTUsInNvdXJjZSI6Imd1cHlfcG9ydGFsIn0=" --format plain
```

See `../SKILL.md` for the full flag reference and the Terms-of-Service note.

## Search flags

| Flag | Alias | Description |
|------|-------|--------------|
| `--query` | `-q` | Keywords (job title, skill, or role), e.g. `"Analista de Dados"`. |
| `--location` | `-l` | City name filter, e.g. `"São Paulo"`. Maps to Gupy's `city` param. |
| `--jobage` | | Posted within N days — filtered client-side (the API has no age param). |
| `--workplaceType` | | `remote` \| `hybrid` \| `on-site`. |
| `--page` | | 1-indexed page (10 results/page, matching the API's own default). |
| `--limit` | `-n` | Cap results emitted. |
| `--format` | | `json` \| `table` \| `plain`. |
