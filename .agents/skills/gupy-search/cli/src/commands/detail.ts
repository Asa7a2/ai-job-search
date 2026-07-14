import { DETAIL_URL, jsonFetch, toJobDetail, normalizeId, writeError, type GupyRawJob } from "../helpers.js"

export interface DetailOpts {
  id: string
  format: "json" | "plain"
}

export async function runDetail(opts: DetailOpts): Promise<number> {
  const id = normalizeId(opts.id)
  if (!id) {
    writeError(`Could not parse a job ID from "${opts.id}"`, "BAD_ID")
    return 1
  }
  try {
    const job = await jsonFetch<GupyRawJob>(`${DETAIL_URL}/${id}`)
    if (!job) {
      writeError("Job not found", "NOT_FOUND")
      return 1
    }
    const detail = toJobDetail(job)

    if (opts.format === "plain") {
      const lines = [
        detail.title,
        `${detail.company || "—"} · ${detail.location || "—"}`,
        "",
        detail.workplaceType ? `Workplace: ${detail.workplaceType}` : "",
        detail.jobType ? `Type: ${detail.jobType}` : "",
        detail.applicationDeadline ? `Application deadline: ${detail.applicationDeadline}` : "",
        "",
        detail.description || "(no description)",
        "",
        `URL: ${detail.url}`,
      ].filter((l) => l !== "")
      process.stdout.write(lines.join("\n") + "\n")
    } else {
      process.stdout.write(JSON.stringify(detail, null, 2) + "\n")
    }
    return 0
  } catch (e) {
    writeError(e instanceof Error ? e.message : String(e), "DETAIL_FAILED")
    return 1
  }
}
