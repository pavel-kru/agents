---
sources:
  - https://code.claude.com/docs/en/memory.md
  - https://code.claude.com/docs/en/skills.md
  - https://code.claude.com/docs/en/settings.md
verified: 2026-10-21
claude_code: 2.1.303
---

# What gets loaded, and when

## At session start

- `CLAUDE.md` / `CLAUDE.local.md` in the working directory and in every directory
  above it, plus the user (`~/.claude/CLAUDE.md`) and managed files. **(docs)**
- They are **concatenated, not overridden**. When two instructions contradict each
  other, the model may follow either one. **(docs)** See `precedence.md`.
- CLAUDE.md content arrives as a user message after the system prompt, and strict
  compliance isn't guaranteed. **(docs)**
- `@path` imports load with the importing file, resolved relative to that file, up
  to four hops deep. An import that points outside the working directory needs a
  one-time approval. **(docs)**
- Skills: only the descriptions are in context. A skill's body loads when the
  skill is invoked. **(docs)**
- `.claude/settings.json` (hooks, permissions, env) is read only from the
  directory the session starts in. **(docs)**

## Later, on demand

- A `CLAUDE.md` in a **subdirectory** loads the first time Claude reads, writes or
  edits a file in that subdirectory. **(docs; verified: nested repo, transcript)**
- `.claude/rules/*.md` with a `paths:` list loads when Claude reads, writes or
  edits a matching file. **(verified: transcript shows a `nested_memory`
  attachment right after the Read, and nothing before it)**
  - Globs are relative to the repo that holds the rule, and that holds for a
    nested repo's rules too. **(verified)**
  - Single, double or no quotes around the globs all work. **(verified)**
  - A rule without `paths:` loads at start. **(docs)**
- Skills in a nested `.claude/skills/` appear after the first touch of a file in
  that subdirectory. **(docs; observed)**

## Traps

- **An `@import` inside a path-scoped rule loads eagerly at session start.** The
  rule's own body stays lazy, but the imported file doesn't. Put the content in
  the rule itself if it should load lazily. **(verified)**
- **A sibling directory is never loaded.** It isn't the working directory, a
  parent or a child. **(verified)** See `multi-repo.md`.
- **`AGENTS.md` is read only when no `CLAUDE.md` exists.** With both present, add
  `@AGENTS.md` to `CLAUDE.md`. **(docs)**
- **A README holding rules is data, not instructions.** It reaches the model only
  if the model decides to read it. Import it (`@README.md`) when it is the
  rulebook. **(verified: transcript)**

## Cost

Everything loaded at start is paid for in every session. Keep `CLAUDE.md` under
about 200 lines including its imports. **(docs)** Move topic docs that apply to
one area into path-scoped rules. **(opinion)**
