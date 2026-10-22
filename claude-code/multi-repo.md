---
sources:
  - https://code.claude.com/docs/en/memory.md
  - https://code.claude.com/docs/en/settings.md
  - https://code.claude.com/docs/en/skills.md
verified: 2026-10-21
claude_code: 2.1.303
status: proven
---

# Several repositories in one session

Typical layout: a pipeline repo (skills, runbook) next to front-end, back-end,
docs and tests repos.

## What each layout gives you

| Session starts in | Other repo's CLAUDE.md | its `paths:` rules | its hooks | pipeline skills |
|---|---|---|---|---|
| pipeline repo, others are **siblings** | ❌ | ❌ | ❌ | ✅ |
| pipeline repo + `--add-dir ../other` | only with `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` | ❌ | ❌ | ✅ |
| pipeline repo + `permissions.additionalDirectories` in settings | ❌ (access only) | ❌ | ❌ | ✅ |
| the repo being changed + `--add-dir ../pipeline` | ✅ | ✅ | ✅ (its own) | ✅ |
| a root repo with the others **cloned inside it** | ✅ on first touch | ✅ on first touch | root's only | ✅ |
| a plain parent folder | ✅ on first touch | — | ❌ none | on first touch |

All rows were **verified with `claude -p` and transcripts**, except the last
row's `paths:` cell, which wasn't tested. The env variable also works when it is
set in `settings.json` under `env`. **(verified)**

## Rules of thumb

- **Start the session in the repo you are writing to.** Everything that repo
  defines works there. **(opinion, follows from the table)**
- A skill that writes to another repo should list that repo's `CLAUDE.md`, and
  anything it `@`-imports, as its first input. That is advisory, but it is the
  only way the other repo's rules reach a session started elsewhere.
- **Check each repo's branch before branching for a cross-repo change.** In one
  session, one of four sibling repos was on an unrelated feature branch, and
  `git switch -c fix/x` there would have stacked the fix on it. Fetch, then
  branch every repo from the remote default explicitly:
  `git switch -c fix/x origin/main`. **(practice; the stray branch was observed)**
- For one declarative entry point, use a root repo with the others cloned inside
  it and listed in its `.gitignore`. It costs a migration of everyone's paths.
- Plugins (a marketplace plus `enabledPlugins` in each repo's settings) can ship
  skills and hooks to every repo, at the price of namespaced skill names.
  **(docs, not tested)**

## Search with nested clones

ripgrep, which runs Claude's Grep, honours the root `.gitignore`, so **Grep from the
root doesn't see gitignored nested repos**. **(verified)** Add a root `.ignore`
file, which git doesn't read:

```gitignore
!/front/
!/back/
```

The nested repo's own `.gitignore` (`node_modules/`) still applies. **(verified)**
Glob ignored `.gitignore` either way in the same test. **(verified)**

## Parallel sessions in one repo

One working tree can't safely host two agents. Give each one a `git worktree`:
- each worktree has its own index, so there are no `index.lock` fights;
- each worktree builds into its own `dist/`;
- **the stash stack is shared** between worktrees, so use WIP commits instead of
  `git stash pop`.

See `pitfalls.md` for the shared-`node_modules` trap.
