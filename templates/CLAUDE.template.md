# <Repo name>

<One paragraph: what this repo is, its stack, its place among the other repos.>

## Rules you must follow

1. <Invariant>. Enforced by <linter/test/hook>; don't disable it.
2. <Invariant that only prose covers today, and why.>
3. Never hand-edit <generated file>; regenerate it with `<command>` (a hook
   blocks Edit/Write on it).
4. Commits: <format>. Never commit to `main`.

## When sources disagree

- A direct instruction from the human in the session wins over these files.
- Facts (what the code does, API shapes, where files are) come from the code,
  generated artifacts and tests. A doc that disagrees is stale.
- The rules above win over the topic docs, which only add detail. Existing code
  that breaks a rule is not a pattern to copy.
- If you can't settle it, don't pick silently. Fix the doc on your branch, or say
  so in the PR.

## Where to look

Docs under `.claude/rules/` load by themselves when you touch matching files.
Read the others when the task needs them.

| Task | Read |
| --- | --- |
| <topic> | `.claude/rules/<topic>.md` |
| <topic> | `docs/<topic>.md` |
