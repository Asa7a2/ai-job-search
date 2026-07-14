# Search Queries for Job Scraper

## Search Tools

The Danish CLI tools shipped in this repo (Jobindex, Jobbank, Jobdanmark, Jobnet) do not
apply to Amanda's market (Brazil) and are not used. Active tools:

- **linkedin-search** - `.agents/skills/linkedin-search/` - global, `--location` free text, `--remote remote|hybrid|onsite`
- **freehire-search** - `.agents/skills/freehire-search/` - tech-focused aggregator, geography via `--region`/`--country` facets (`--country BR`, `--region latam`)
- **gupy-search** - `.agents/skills/gupy-search/` - Brazil-specific, searches Portal Gupy (aggregates every company on Gupy's ATS), `--location` is a city name, `--workplaceType remote|hybrid|on-site`. Personal-use only (Gupy ToS) - keep volume low.

Optional future addition: run `/add-portal` for another Brazil-specific board (InfoJobs, Catho, Indeed Brasil) if coverage proves thin.

## Query Categories

### Priority 1: Analista de Dados (Sênior/Pleno)

Primary target role - direct continuation of current title.

```bash
bun run .agents/skills/linkedin-search/cli/src/cli.ts search -q "Analista de Dados" -l "São Paulo, Brazil" --remote hybrid --jobage 14 --format table
bun run .agents/skills/linkedin-search/cli/src/cli.ts search -q "Analista de Dados" -l "Brazil" --remote remote --jobage 14 --format table
bun run .agents/skills/freehire-search/cli/src/cli.ts search -q "data analyst" --country BR --jobage 14 --format table
bun run .agents/skills/gupy-search/cli/src/cli.ts search -q "Analista de Dados" -l "São Paulo" --workplaceType hybrid --jobage 14 --format table
bun run .agents/skills/gupy-search/cli/src/cli.ts search -q "Analista de Dados" --workplaceType remote --jobage 14 --format table
```

### Priority 2: Engenharia de Dados (Pleno)

Equally primary target - the direction her current role has been growing into (pipelines, CDC, Lakehouse architecture).

```bash
bun run .agents/skills/linkedin-search/cli/src/cli.ts search -q "Engenheiro de Dados" -l "São Paulo, Brazil" --remote hybrid --jobage 14 --format table
bun run .agents/skills/linkedin-search/cli/src/cli.ts search -q "Data Engineer" -l "Brazil" --remote remote --jobage 14 --format table
bun run .agents/skills/freehire-search/cli/src/cli.ts search -q "data engineer" --country BR --seniority middle --jobage 14 --format table
bun run .agents/skills/gupy-search/cli/src/cli.ts search -q "Engenheiro de Dados" -l "São Paulo" --workplaceType hybrid --jobage 14 --format table
```

### Priority 3: Analytics Engineer / BI Analyst (adjacent)

Roles she could pivot into directly given her Power BI/DAX + pipeline background; her LinkedIn headline already claims this range.

```bash
bun run .agents/skills/linkedin-search/cli/src/cli.ts search -q "Analytics Engineer" -l "Brazil" --remote remote --jobage 14 --format table
bun run .agents/skills/linkedin-search/cli/src/cli.ts search -q "BI Analyst Power BI" -l "São Paulo, Brazil" --remote hybrid --jobage 14 --format table
bun run .agents/skills/freehire-search/cli/src/cli.ts search --skill python,sql,power-bi --country BR --jobage 14 --format table
bun run .agents/skills/gupy-search/cli/src/cli.ts search -q "Analista BI Power BI" -l "São Paulo" --workplaceType hybrid --jobage 14 --format table
```

### Priority 4: Broader / LATAM remote net

Wider net when Priority 1-3 results are thin.

```bash
bun run .agents/skills/linkedin-search/cli/src/cli.ts search -q "Data Lakehouse Databricks Fabric" -l "Remote" --jobage 14 --format table
bun run .agents/skills/freehire-search/cli/src/cli.ts search -q "data" --region latam --remote remote --jobage 14 --format table
bun run .agents/skills/gupy-search/cli/src/cli.ts search -q "dados" --workplaceType remote --jobage 14 --format table
```

## Location Filter

Amanda is not open to presencial-only roles outside São Paulo capital, and not open to relocation.

- **São Paulo (capital)** - hybrid: PASS
- **Remote, based anywhere in Brazil** - PASS
- **Presencial or hybrid outside São Paulo capital** - FAIL (deal-breaker)
- **Requires relocation** - FAIL (deal-breaker)
- Remote roles based outside Brazil but open to Brazil-based remote hires - borderline, flag for discussion (time zone / contract-type check needed)

## Date Filter

Only include jobs posted within the last 14 days, or with an application deadline that has not yet passed. If a posting date cannot be determined, include it but flag as "date unknown".

## Adapting Queries

If the user specifies a focus area, select queries from the matching category and also generate 2-3 custom queries for that focus. For example:
- "/scrape [focus_area]" -> relevant category queries + custom focus-specific queries
