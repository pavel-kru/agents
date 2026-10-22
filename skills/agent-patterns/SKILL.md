---
name: agent-patterns
description: The user's verified patterns for running Claude Code agents, kept in ~/agents. They cover which instruction files load when (CLAUDE.md, imports, rules with paths, skills, settings), what wins when instructions disagree, enforcing rules with hooks, sessions spanning several repos, multi-agent pipelines, and proving what a session loaded. Use when setting up or debugging CLAUDE.md, rules, skills, hooks or settings, when designing an agent workflow, or when you learned something reusable about how Claude Code behaves that should be saved as a new pattern (/agent-patterns add).
---

# Agent patterns (~/agents)

The repo at `~/agents` holds reusable patterns, templates and scripts. Every
claim in it is labelled **(verified: how)**, **(docs)** or **(opinion)**. Each
pattern's front-matter lists the official docs it relies on and the date and
Claude Code version it was checked against.

## Using a pattern

1. Read `~/agents/README.md` (the index) and then only the files the task needs.
2. Check freshness before relying on a claim. Run
   `node ~/agents/scripts/check-docs.mjs --force`: no output means the cited docs
   are unchanged. If it lists changes, tell the user that the affected patterns
   may be stale. Only update them if the user wants that now (see "Updating"
   below).
3. Treat an **(opinion)** claim as advice and a **(docs)** claim as something to
   re-read when it matters. A **(verified)** claim was observed on the recorded
   version.

## Adding or changing a pattern ("add")

1. **Generalise.** No project or company names, hosts, people, ids or internal
   paths. Use "the front-end repo", "the generated contract" and so on.
2. **Place it.** Extend the closest file in the README index, or create a new
   file with the front-matter:
   ```yaml
   ---
   sources: [<official .md doc URLs it relies on>]   # or [] for practice-only patterns
   verified: <YYYY-MM-DD>
   claude_code: <version from `claude --version`>
   ---
   ```
   Add a new file to the README table.
3. **Label every claim** with its evidence. Something the model said about its
   own context is not evidence: verify with `claude -p` and
   `node ~/agents/scripts/transcript-inspect.mjs`, as described in
   `~/agents/claude-code/verification.md`.
4. If you added a docs URL, run `node ~/agents/scripts/check-docs.mjs --update-lock`.
5. **Don't commit on your own.** Show the user the diff
   (`git -C ~/agents status --short`, `git -C ~/agents diff`) and commit and push
   only when they ask for it in that turn. Never add a Claude co-author trailer.

## Updating after the docs changed

Follow "Keeping the patterns current" in `~/agents/CLAUDE.md`:
1. read each changed page;
2. fix or remove the claims it no longer supports;
3. re-verify;
4. bump `verified` and `claude_code`;
5. run `--update-lock`.
