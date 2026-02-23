---
description: Generate a digest of interesting things being shipped across Datadog, pulling from dd-source and web-ui
argument-hint: [--period=1w|1m|3m] [--save]
allowed-tools:
  - Bash(git -C * log *)
  - Bash(wc -l *)
  - Bash(mkdir *)
---

# Release Digest

Generate a comprehensive, categorized digest of interesting things being shipped across Datadog by analyzing recent merge activity in dd-source and web-ui.

## Interaction Rules

**This skill must be interactive.** Use `AskUserQuestion` for all user input — NEVER output plain text and wait for a response. Plain text without an interactive widget looks like the skill has crashed.

The only exception: progress updates ("Fetching dd-source...", "Classifying 847 PRs in 4 batches...") are fine as plain text since they don't require a response.

---

## Phase 1: Parse Arguments & Select Timeframe

Parse `$ARGUMENTS` for:
- **--period**: `1w` (1 week), `1m` (1 month), `3m` (3 months). If not provided, prompt interactively.
- **--save**: If set, save the markdown digest to `~/release-digests/digest-{date}.md`

### If no --period provided, ask:

Use `AskUserQuestion`:
- Question: "What time period should I cover?"
- Options:
  - "Last 1 week (Recommended)" with description "Best for a focused weekly digest. Covers ~500-1000 PRs across both repos."
  - "Last 1 month" with description "Broader view. Covers several thousand PRs — classification will take longer."
  - "Last 3 months" with description "Quarterly overview. Very high volume — will sample and summarize at a higher level."

Convert the selection to a `--since` date string relative to today.

---

## Phase 2: Repo Locations & Data Extraction

### Repo Paths

The repos live at:
- **dd-source**: `$HOME/go/src/github.com/DataDog/dd-source`
- **web-ui**: `$HOME/go/src/github.com/DataDog/web-ui`

### Extract dd-source PRs

dd-source uses squash merges, so PR titles ARE the commit messages on `origin/main`.

```bash
git -C <dd-source-path> log --first-parent --since="<date>" --pretty=format:"%h|%ai|%s" origin/main
```

Each line gives: `short_hash|date|PR title`

The PR titles typically follow patterns like:
- `[TICKET-ID] Description (#PR_NUMBER)`
- `feat(scope) Description (#PR_NUMBER)`
- `Plain description (#PR_NUMBER)`

### Extract web-ui PRs

web-ui uses a mix of merge commits and squash merges. The main integration branch is `origin/preprod` (NOT `origin/main`).

Use a format that includes the commit body, with a delimiter to split entries:

```bash
git -C <web-ui-path> log --first-parent --since="<date>" --pretty=format:"---ENTRY---%h|%ai|%s%n%b" origin/preprod
```

Split the output on `---ENTRY---` to get individual commits. For each:

- **Squash merges** (subject does NOT start with `Merge pull request`): The subject IS the PR title — use it directly.
- **Merge commits** (subject starts with `Merge pull request #N from DataDog/`): Extract the PR number from the subject. Then use the **first non-empty line of the body** as the PR title — GitHub stores the PR title there. If the body is empty, fall back to parsing the branch name from the subject (replace hyphens with spaces, strip the `author/` prefix).

### Volume Check

Count the total PRs extracted from both repos. Report to the user:
> Found {N} PRs in dd-source and {M} PRs in web-ui ({total} total) over the last {period}.

**Volume handling:**
- **< 2,000 total**: Process all. Proceed normally.
- **2,000 - 5,000 total**: Warn: "This is a lot of PRs. Classification will take a few minutes." Proceed.
- **> 5,000 total**: Use `AskUserQuestion`:
  - "Found {total} PRs — that's a lot. How should I handle this?"
  - Options:
    - "Process all (may take 5-10 minutes)"
    - "Sample ~2,000 evenly across the period (faster, still representative)"
    - "Use a shorter time period"

---

## Phase 3: Noise Filtering

Before classification, filter out low-signal PRs. Remove PRs whose titles match these patterns (case-insensitive):

**Auto-filter (always remove):**
- Dependency bumps: `bump`, `upgrade.*dependency`, `yarn upgrade`, `go mod tidy`, `chore(streaming): Bump`
- CI/infra maintenance: `fix flaky`, `fix ci`, `update codeowners`, `codeowners/`, `revert "revert`
- Merge housekeeping: titles that are ONLY `Merge branch 'main'` or similar
- Bot-generated: `[bot]`, `dependabot`, `renovate`
- Config syncs: `consul-config`, `static app version sync`

**Keep everything else** — even things that look minor. The LLM classification step will handle relevance.

Report the filtering:
> Filtered out {N} noise PRs (dependency bumps, CI fixes, bot commits). {remaining} PRs proceeding to classification.

---

## Phase 4: LLM Classification (Parallel Batches)

### Batching Strategy

- **Model**: Use `haiku` for classification — it's fast, cheap, and PR title classification is straightforward.
- **Batch size**: 150 PRs per batch (PR titles are short, this fits comfortably in context).
- Calculate number of batches: `ceil(total_prs / 150)`
- Report: "Classifying {total} PRs in {num_batches} batches using parallel agents..."

### Classification Prompt

Launch parallel sub-agents (using the Task tool with `subagent_type: "general-purpose"`, `model: "haiku"`). Each sub-agent receives a batch of PR titles and these instructions:

```
You are classifying pull requests from Datadog's internal repositories to build a company release digest. For each PR, classify it into exactly ONE product category and ONE change type.

## Product Categories (pick the best fit):
- **APM & Tracing**: Application performance monitoring, traces, profiling, service catalog, universal service monitoring
- **Infrastructure**: Host monitoring, containers, processes, serverless, cloud integrations, network monitoring
- **Logs & SIEM**: Log management, log pipelines, SIEM, security monitoring, Cloud SIIEM
- **Security**: Application security (ASM), cloud security (CSM/CSPM), workload security, vulnerability management
- **Dashboards & Visualization**: Dashboards, widgets, notebooks, graphing, metrics explorer
- **Monitors & Alerting**: Monitors, alerts, downtime, SLOs, incident management, on-call
- **AI & LLM Observability**: LLM observability, AI integrations, ML model monitoring, Bits AI, MCP
- **CI/CD & Testing**: CI Visibility, test optimization, synthetic testing, continuous testing
- **Real User Monitoring**: RUM, session replay, mobile monitoring, browser testing
- **Database Monitoring**: DBM, query performance, database integrations
- **Developer Experience**: Internal tools, developer workflows, IDE integrations, code search
- **Platform & Core**: Authentication, RBAC, billing, org management, API, audit trail
- **Data Platform**: Metrics ingestion, storage, query engine, data pipelines, streaming
- **UI Framework & Design System**: DRUIDS components, design system, shared UI infrastructure
- **Internal Tooling & Ops**: Build systems, deployment, internal services, infrastructure automation

## Change Types:
- **New Feature**: Entirely new capability or product surface
- **Enhancement**: Improvement to existing functionality
- **Bug Fix**: Fixing broken behavior
- **Performance**: Performance optimization
- **Refactor**: Code restructuring without behavior change
- **Migration**: Moving between systems, upgrading frameworks

## Interestingness (1-5):
Rate how interesting this would be to someone wanting to know what's happening across the company:
- 5: Major new feature, new product capability, significant launch
- 4: Notable enhancement, interesting technical work
- 3: Solid improvement, worth mentioning in a digest
- 2: Routine work, minor enhancement
- 1: Trivial, not worth mentioning

For each PR, return:
{"title": "<original PR title>", "repo": "<dd-source or web-ui>", "category": "<category>", "change_type": "<type>", "interest": <1-5>, "summary": "<1 sentence plain-English summary of what this does>"}

Return results as a JSON array. Be generous with interest scores for genuinely new capabilities, AI/ML work, and cross-cutting platform changes — those are the most interesting to a broad audience.

Here are the PRs to classify:
```

**Parallelism**: Launch up to 8 sub-agents concurrently. If more than 8 batches, process in waves.

### Collect & Merge Results

Merge all batch results into a single array. Apply a **timeframe-scaled interest threshold**:
- **1 week or 1 month**: Drop PRs with `interest < 3`
- **3 months**: Drop PRs with `interest < 4` (otherwise the digest is unreadably long)

Report: "Classification complete. {high_interest} PRs rated notable out of {total} classified (threshold: interest >= {threshold})."

---

## Phase 5: Generate the Digest

### Structure

Organize the remaining PRs (those above the interest threshold) into the final digest. Sort categories by the number of high-interest PRs (most active areas first).

### Output Format

Render the digest as markdown, printed to the terminal:

```markdown
# Datadog Release Digest — {start_date} to {end_date}

> Covering {total_prs_analyzed} PRs across dd-source and web-ui. {high_interest_count} notable changes highlighted below.

---

## Highlights (interest 5)

> The most significant launches and new capabilities this period.

- **[Category]** Summary of the PR. `dd-source#12345` or `web-ui#67890`
- ...

---

## {Category Name} ({count} notable changes)

### New Features
- Summary of PR. `repo#number`
- ...

### Enhancements
- Summary of PR. `repo#number`
- ...

### Other
- Summary of PR. `repo#number`
- ...

---

## {Next Category} ({count} notable changes)

...

---

## Digest Stats

| Metric | Value |
|--------|-------|
| Period | {start} to {end} |
| Total PRs scanned | {total} |
| After noise filtering | {filtered} |
| Notable (interest 3+) | {notable} |
| Highlights (interest 5) | {highlights} |
| Categories covered | {num_categories} |
| dd-source PRs | {dd_count} |
| web-ui PRs | {webui_count} |
```

### Writing Rules

- **Summaries must be plain English**, not the raw PR title. Translate jargon and ticket IDs into what it actually means.
- **Group related PRs**. If 5 PRs all relate to the same feature launch, summarize them together as one bullet.
- **Include the PR reference** (repo#number) so the reader can dig deeper.
- **Lead with the "Highlights" section** — interest-5 items only. This is the TL;DR.
- **Within each category**, group by change type (New Features first, then Enhancements, then Other).
- **Skip empty categories** — if a category has no PRs above the interest threshold, omit it entirely.

---

## Phase 6: Save (Optional)

If `--save` was set:

1. Create directory if needed: `~/release-digests/`
2. Write the digest to: `~/release-digests/digest-{YYYY-MM-DD}.md`
3. Inform the user: "Digest saved to ~/release-digests/digest-{date}.md"

If `--save` was NOT set, after displaying the digest, mention:
> Tip: Re-run with `--save` to write this digest to a file for sharing.

---

## Phase 7: Follow-Up

After the digest is displayed, offer follow-up options using `AskUserQuestion`:

- Question: "Anything you'd like to explore further?"
- Options:
  - "Deep-dive into a category" with description "Pick a product area to see ALL PRs (including lower-interest ones)"
  - "Show me the raw data" with description "Display the full classified PR list as a table"
  - "I'm done" with description "End the digest"

If "Deep-dive into a category": use another `AskUserQuestion` to let them pick which category, then display all PRs in that category (including interest 1-2), sorted by interest descending.

---

## Error Handling

- **Repo not found**: Check if the repo path exists. If not, tell the user and ask for the correct path.
- **No commits in range**: The local refs are likely stale. Tell the user to fetch the repos and re-run.
- **Sub-agent classification fails**: Retry the batch once, then skip and note the gap in the output.
- **Extremely large volume (>10k PRs)**: Force sampling to 2,000 PRs with a warning.
