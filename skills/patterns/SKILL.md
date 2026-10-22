---
name: patterns
description: Index of the user's engineering patterns in ~/patterns, and how to add one. Domains so far - Claude Code agents (claude-code/, skill patterns-claude-code) and security (security/, skill patterns-security). Use to save something reusable you learned as a new pattern (/patterns add), or to look up a pattern when no domain skill fits.
---

# Patterns (~/patterns)

The repo at `~/patterns` holds reusable patterns, templates and scripts, one folder
per domain. Every claim is labelled **(verified: how)**, **(docs)** or
**(opinion)**. Each pattern's front-matter lists the docs it relies on, the date
it was checked, its `status` and, for Claude Code patterns, the Claude Code
version.

## Using a pattern

1. Read `~/patterns/README.md` (the index by domain) and then only the files the
   task needs.
2. Check freshness before relying on a claim. Run
   `node ~/patterns/scripts/check-docs.mjs --force`: no output means the cited
   docs are unchanged. If it lists changes, tell the user that the affected
   patterns may be stale. Only update them if the user wants that now (see
   "Updating" below).
3. Weigh what you read:
   - `status: proven`: the key claims were verified or the pattern was applied
     in real work. `status: candidate`: reviewed or reasoned, not yet proven.
   - **(verified)** was observed on the recorded version, **(docs)** is worth
     re-reading when it matters, **(opinion)** is advice.

## Adding or changing a pattern ("add")

1. **Generalise.** No project or company names, hosts, people, ids or internal
   paths. Use "the front-end repo", "the generated contract" and so on.
2. **Place it.** Extend the closest file in the README index, or create a new
   file in its domain folder with the front-matter:
   ```yaml
   ---
   sources: [<official doc URLs it relies on, .md where one exists>]   # or [] for practice-only patterns
   verified: <YYYY-MM-DD>
   claude_code: <version from `claude --version`>     # Claude Code patterns only
   status: candidate                                  # proven once verified or applied in real work
   ---
   ```
   Add a new file to its domain table in the README.
3. **A new domain** gets its folder with its first pattern, never before. In the
   same change add a README section and a `skills/patterns-<domain>/SKILL.md`
   (copy `patterns-security` as the template), add the domain to this skill's
   description, then run `~/patterns/install.sh`.
4. **Label every claim** with its evidence. Something the model said about its
   own context is not evidence: verify with `claude -p` and
   `node ~/patterns/scripts/transcript-inspect.mjs`, as described in
   `~/patterns/claude-code/verification.md`.
5. If you added a docs URL, run
   `node ~/patterns/scripts/check-docs.mjs --update-lock`.
6. **Don't commit on your own.** Show the user the diff
   (`git -C ~/patterns status --short`, `git -C ~/patterns diff`) and commit and
   push only when they ask for it in that turn. Never add a Claude co-author
   trailer.

## Updating after the docs changed

Follow "Keeping the patterns current" in `~/patterns/CLAUDE.md`:
1. read each changed page;
2. fix or remove the claims it no longer supports;
3. re-verify;
4. bump `verified` (and `claude_code` in Claude Code patterns);
5. run `--update-lock`.
