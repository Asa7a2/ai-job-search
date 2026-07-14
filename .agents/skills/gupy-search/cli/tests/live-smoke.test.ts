import { describe, test, expect } from "bun:test";
import { runCLI, parseJSON } from "./helpers";

// Hits the live Gupy API. Keep this file minimal — one search, one bogus-arg check —
// per the repo's "keep volume low" convention for personal-use portal skills.

interface SearchResult {
  meta: { count: number; page: number };
  results: Array<{ id: string | null; title: string | null; company: string | null; location: string | null; date: string | null; url: string | null }>;
}

describe("live smoke test (hits employability-portal.gupy.io)", () => {
  test("search for 'Analista de Dados' returns real results", async () => {
    const result = await runCLI(["search", "-q", "Analista de Dados", "--limit", "5"]);
    expect(result.exitCode).toBe(0);
    const parsed = parseJSON<SearchResult>(result);
    expect(parsed.results.length).toBeGreaterThan(0);
    const first = parsed.results[0];
    expect(first.id).not.toBeNull();
    expect(first.title).not.toBeNull();
    expect(first.url).not.toBeNull();
  }, 30000);

  test("a bogus flag value exits 1 with a JSON error on stderr", async () => {
    const result = await runCLI(["search", "-q", "Analista de Dados", "--jobage", "not-a-number"]);
    expect(result.exitCode).toBe(1);
    const err = JSON.parse(result.stderr);
    expect(err.code).toBe("BAD_ARG");
  });
});
