# patterns — reusable engineering patterns

Reusable patterns, templates and scripts taken from real projects, one folder per
domain: Claude Code agents (`claude-code/` and the root files), security
(`security/`). **Patterns only**: no project or company names, hosts, people, account
ids or internal paths. Say "the front-end repo" or "the generated contract", not
a real repo name.

@README.md

## Keeping the patterns current

Docs and tools change often, so every pattern records where it came from and what
it was checked against:

```yaml
---
sources:            # official docs pages the pattern relies on (.md URLs)
  - https://code.claude.com/docs/en/memory.md
verified: 2026-10-21  # date of the last check
claude_code: 2.1.303  # Claude Code version it was checked on
status: proven      # or candidate
---
```

`claude_code` belongs only in patterns about Claude Code. Leave it out elsewhere:
`check-docs.mjs` compares the installed version only with patterns that have it.

`status: proven` means the key claims were verified or the pattern was applied in
real work. `status: candidate` means it was reviewed or reasoned but not yet
proven. Promote a candidate when it holds up a second time.

At session start a hook runs `scripts/check-docs.mjs`. The script compares every
cited page with the version it was verified against (`docs.lock.json`), and the
installed Claude Code version with the newest `claude_code` in the patterns. It
prints a report only when something changed.

When the report lists changes:

1. Read each changed page. Fetch the `.md` URL itself, not a summary of it.
2. Update every pattern that cites the page. A claim the docs no longer support
   gets fixed or removed, never kept on trust.
3. Re-verify what you can with `claude-code/verification.md`, then bump
   `verified` and `claude_code` in the patterns you touched.
4. Run `node scripts/check-docs.mjs --update-lock`.

If the report says the docs can't be reached, treat the patterns as unverified for
this session and say so when you rely on one.

## Hooks in this repo (`.claude/settings.json`)

| Event | Script | Effect |
|---|---|---|
| SessionStart | `scripts/check-docs.mjs` | reports changed docs or a newer Claude Code, at most once a day |
| UserPromptSubmit | `.claude/hooks/record-commit-approval.sh` | a prompt starting with `commit` / `ship it` / `lgtm` / `pr` approves one commit |
| PreToolUse(Bash) | `.claude/hooks/require-commit-review.sh` | `git commit` without that approval is denied |
| PreToolUse(Bash) | `.claude/hooks/block-claude-coauthor.sh` | a Claude/Anthropic co-author trailer is denied |
| Stop | `.claude/hooks/check-doc-coverage.sh` | a file listed in `.claude/doc-coverage.json` changed after its doc: update the doc or say why not |
| Stop | `.claude/hooks/check-sync.sh` | uncommitted or unpushed work: show it and ask the user |

They run only in sessions started here. From anywhere else, the `patterns` skill
(`skills/`, linked by `install.sh`) carries the same rules as text.

## Writing or editing a pattern

- One topic per file, with the front-matter above.
- One folder per domain, created with its first pattern, never before. A new
  domain also gets a README section and a `skills/patterns-<domain>/` skill, and
  the `patterns` skill's description names it. Keep each skill's description
  short: Claude Code truncates `description` plus `when_to_use` at 1,536
  characters in the skill listing. **(docs)**
- Label every claim with its evidence: **(verified: how)**, **(docs)**, or
  **(opinion)**. Something learned from the model's own answer about its context
  is not evidence; see `claude-code/verification.md`.
- Prefer what the harness enforces (hooks, permissions, `paths:`) over what prose
  asks for, and say which one a pattern relies on.
- Keep files short. If a pattern needs a story to make sense, the pattern isn't
  finished yet.
