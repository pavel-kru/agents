---
sources: []
verified: 2026-10-21
claude_code: 2.1.303
---

# Multi-agent pipelines

From a pipeline that rebuilds a legacy app one page ("slice") at a time with
roughly ten agents: scope, docs, manual, QA writer, QA on old UI, QA on new UI,
back-end dev, front-end dev, two reviewers, deploy. **(opinion, from practice)**

## Hand-offs carry artifacts, never transcripts

- Each stage reads files and writes files: docs, specs, a contract, a PR.
  The previous session's transcript is not an input.
- **A reviewer gets only the spec and the diff.** A reviewer who shares the
  builder's context ends up approving its own work.
- **The QA writer derives tests from the document only, never from the code.**
  If the document is wrong, the tests fail against the old system, and that
  failure is the pipeline doing its job.
- A link to the session that produced an artifact is fine for audit. It never
  becomes context.

## Artifact formats

- Markdown from templates, with a fixed YAML front-matter (`slice`, `routes`,
  `source`, `permissions`, `depends_on`, `owner`). Agents read the header, humans
  read the body. Validate it (`instruction-design.md`).
- The as-is document records quirks as regression behaviour (`as-is oddity:`).
  The to-be spec starts as a verbatim copy of it. Every deliberate change is a
  human edit in a change log, and the diff between the two doubles as release
  notes.
- The contract between back end and front end is **generated**: OpenAPI from
  code, then TypeScript types. Tests keep it truthful. Nobody hand-writes a
  shape the generator has.
- Acceptance criteria are **executable**. The same e2e suite runs against the old
  and the new UI: a green run on old proves the doc, a green run on new proves
  parity.

## Isolation and concurrency

- Each stage writes to its own repo and branch (`<key>-<slice>-<stage>`).
  Stages that run in parallel write to different repos.
- The ticket status is the lock: one status, one stage, one skill.
- Two sessions in one repo get two `git worktree`s (`claude-code/multi-repo.md`).

## Gates and loops

- Human gates read reports (test runs, the doc→spec diff), not the documents.
- Cap review rounds at three, then hand to a named human. Each red QA result goes
  back to the stage that produced the broken artifact.
- Put CI on every PR. Without it a red `main` can sit unnoticed for days, and
  every agent that runs the checks then tries to "fix" a failure it didn't cause.
