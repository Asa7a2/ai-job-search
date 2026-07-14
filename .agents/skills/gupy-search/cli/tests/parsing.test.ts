import { describe, test, expect } from "bun:test";
import { decodeEntities, normalizeId, toJobCard, toJobDetail, jobageToCutoff, type GupyRawJob } from "../src/helpers";

function rawJob(overrides: Partial<GupyRawJob> = {}): GupyRawJob {
  return {
    id: 11629415,
    companyId: 6109,
    name: "Analista de Dados Pl. ",
    description: "Requisitos:&nbsp;SQL avançado &amp; Python.",
    careerPageId: 133924,
    careerPageName: "Nomos - Melhores Investidores",
    publishedDate: new Date().toISOString(),
    applicationDeadline: "2026-09-11",
    isRemoteWork: true,
    city: "",
    state: "",
    country: "Brasil",
    jobUrl: "https://nomos.gupy.io/job/eyJqb2JJZCI6MTE2Mjk0MTUsInNvdXJjZSI6Imd1cHlfcG9ydGFsIn0=?jobBoardSource=gupy_portal",
    workplaceType: "remote",
    disabilities: false,
    skills: [],
    ...overrides,
  };
}

describe("decodeEntities", () => {
  test("decodes &nbsp; to a space", () => {
    expect(decodeEntities("Requisitos:&nbsp;SQL")).toBe("Requisitos: SQL");
  });

  test("decodes &amp; to &", () => {
    expect(decodeEntities("SQL &amp; Python")).toBe("SQL & Python");
  });

  test("decodes multiple entity types together", () => {
    expect(decodeEntities("A &lt;tag&gt; &amp; &quot;quotes&quot;")).toBe('A <tag> & "quotes"');
  });
});

describe("normalizeId", () => {
  test("accepts a bare numeric id", () => {
    expect(normalizeId("11629415")).toBe("11629415");
  });

  test("extracts id from a /jobs/<id> public-page URL", () => {
    expect(normalizeId("https://tech-career.gupy.io/jobs/8891670?jobBoardSource=gupy_public_page")).toBe(
      "8891670",
    );
  });

  test("decodes id from a /job/<base64> portal URL", () => {
    // base64 of {"jobId":11575965,"source":"gupy_portal"}
    const url =
      "https://caju.gupy.io/job/eyJqb2JJZCI6MTE1NzU5NjUsInNvdXJjZSI6Imd1cHlfcG9ydGFsIn0=?jobBoardSource=gupy_portal";
    expect(normalizeId(url)).toBe("11575965");
  });

  test("returns null for unparseable input", () => {
    expect(normalizeId("not-a-job-id")).toBeNull();
  });
});

describe("toJobCard", () => {
  test("maps core fields and never omits the contract's keys", () => {
    const card = toJobCard(rawJob());
    expect(card.id).toBe("11629415");
    expect(card.title).toBe("Analista de Dados Pl.");
    expect(card.company).toBe("Nomos - Melhores Investidores");
    expect(card.url).toContain("nomos.gupy.io");
    expect(card).toHaveProperty("location");
    expect(card).toHaveProperty("date");
  });

  test("location falls back to null when city/state/country are all empty", () => {
    const card = toJobCard(rawJob({ city: "", state: "", country: "", workplaceType: "on-site", isRemoteWork: false }));
    expect(card.location).toBeNull();
  });

  test("marks remote jobs distinctly in location", () => {
    const card = toJobCard(rawJob({ workplaceType: "remote", isRemoteWork: true, city: "", state: "" }));
    expect(card.location).toBe("Remoto");
  });

  test("missing title falls back to a placeholder rather than throwing", () => {
    const card = toJobCard(rawJob({ name: "" }));
    expect(card.title).toBe("(untitled)");
  });
});

describe("toJobDetail", () => {
  test("decodes entities in the description", () => {
    const detail = toJobDetail(rawJob());
    expect(detail.description).toBe("Requisitos: SQL avançado & Python.");
  });

  test("carries workplaceType and applicationDeadline through", () => {
    const detail = toJobDetail(rawJob());
    expect(detail.workplaceType).toBe("remote");
    expect(detail.applicationDeadline).toBe("2026-09-11");
  });
});

describe("jobageToCutoff", () => {
  test("returns null for 9999 (all time)", () => {
    expect(jobageToCutoff(9999)).toBeNull();
  });

  test("returns null for 0 or negative", () => {
    expect(jobageToCutoff(0)).toBeNull();
    expect(jobageToCutoff(-5)).toBeNull();
  });

  test("returns a Date roughly N days in the past", () => {
    const cutoff = jobageToCutoff(7);
    expect(cutoff).not.toBeNull();
    const expected = Date.now() - 7 * 86400 * 1000;
    expect(Math.abs((cutoff as Date).getTime() - expected)).toBeLessThan(5000);
  });
});
