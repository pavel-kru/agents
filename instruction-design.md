---
sources:
  - https://code.claude.com/docs/en/memory.md
  - https://code.claude.com/docs/en/best-practices.md
verified: 2026-10-21
claude_code: 2.1.303
---

# Laying out agent instructions

Most of this is **(opinion)**, backed by the docs where marked.

## The layers

| Layer | Holds | Loads |
|---|---|---|
| `CLAUDE.md` | invariants ("rules you must follow"), the tie-break, a "where to look" table | always |
| `@`-imports in CLAUDE.md | short files that are the rulebook (a README, the runbook, decisions) | always |
| `.claude/rules/*.md` with `paths:` | topic docs tied to one area (API layer, design system, tests) | on touching matching files |
| plain docs (`agents/*.md`, `docs/`) | broad or rarely needed docs | only if the model reads them |
| skills | procedures for one job | descriptions always, body on call |
| hooks, linters, tests, CI | everything that must hold | enforced |

## Rules

- **Short CLAUDE.md.** Keep it under about 200 lines, imports included **(docs)**.
  For each line, ask whether removing it would cause a mistake **(docs)**. Use
  emphasis sparingly **(docs)**.
- **One canonical home per rule.** Everywhere else links to it. A reviewer whose
  context is deliberately narrow is the exception: their checklist must stand on
  its own.
- **Facts vs norms.** Generated artifacts and tests are facts. Docs describe
  norms and must not restate facts that can drift.
- **Invariants become mechanics.** If an agent must never do X, a hook, linter or
  test says so. CLAUDE.md only explains why.
- **Mark staleness instead of hiding it.** A doc may declare itself stale. A dated
  decision record is never rewritten after the fact.
- **The front-matter is the API.** If agents read headers (`slice`, `status`,
  `depends_on` …), validate them in CI, and cross-check them against the
  inventory they reference. A header field that duplicates state kept elsewhere
  (a ticket status) will drift, so drop it.
- **Name where things live.** A skill that touches another repo says "read
  `<repo>/CLAUDE.md` first", because nothing else will load it (`claude-code/multi-repo.md`).
- **Write for the reader who wasn't there.** Lead with the decision or the rule,
  not the history.
