---
sources:
  - https://code.claude.com/docs/en/hooks.md
  - https://code.claude.com/docs/en/hooks-guide.md
verified: 2026-10-21
claude_code: 2.1.303
status: proven
---

# Enforcing rules with hooks

CLAUDE.md asks; hooks make sure. **(docs: "advisory" vs "deterministic")**

## Where hooks sit in a turn

```
UserPromptSubmit → model picks a tool → PreToolUse → permission check → tool runs
  (a Bash `git commit` runs git hooks in here) → PostToolUse → … → Stop
```

| Hook | Use it for |
|---|---|
| PreToolUse | prevention: block the call before it happens |
| PostToolUse | fast feedback, e.g. lint the edited file. It can't undo the call. |
| Stop | an "are we done?" gate. Watch out for loops. |
| git pre-commit / commit-msg | the last line before a commit, for humans and agents alike |
| CI on the PR | the only gate nobody can skip locally |

## Blocking an edit (verified end to end with `claude -p`)

- PreToolUse, matcher `Edit|Write|MultiEdit|NotebookEdit`. Exit code **2** blocks
  the call, and **stderr goes to the model**, so write it as an instruction: say
  what to do instead. **(verified)**
- Match paths by suffix and normalise `\` to `/`. Then one script works for
  relative, absolute and Windows paths. **(verified)**
- Run the script with `node` (or any tool on PATH) through
  `"$CLAUDE_PROJECT_DIR/…"`. Hooks run under `sh -c` on macOS and Linux, and under
  Git Bash (or PowerShell without it) on Windows. **(docs)**
- **The hook config comes from the start directory only.** A session started in
  repo A doesn't run repo B's hooks, even while it edits B. Put the hook where the
  sessions start. **(docs)**
- If `node` isn't on PATH, for example because it is installed through nvm and
  the editor was launched from the GUI, the hook fails with a code other than 2,
  and **the edit goes through**. **(opinion, from how exit codes work)**

See `templates/hooks/` for a working script and settings file.

## What a file-tool matcher doesn't catch

- Writes through Bash: `sed -i`, `cat >`, `tee`.
- `git commit --no-verify`, which skips git hooks.
- Commits or pushes to `main`.

Close these with a PreToolUse hook on `Bash` that inspects the command.
**(opinion)**

## Patterns from practice (working copies in `.claude/hooks/`)

All verified 2026-10-22: unit-tested on macOS `/bin/bash` 3.2 and end to end with
`claude -p`.

- **Commit only on the user's word.** A UserPromptSubmit hook clears a
  per-session marker on every prompt. It creates the marker again only when the
  prompt *starts with* an approval word (`commit`, `ship it`, `lgtm`, `pr`,
  `/pr`), so "don't commit yet" and "why was the PR blocked?" don't count. A
  PreToolUse(Bash) hook then denies `git commit` unless the marker exists, and
  consumes it, so each approval covers exactly one commit. The approval comes
  from the user's words through the harness. If the model touched the marker
  itself, that would be a bypass. **(verified)**
- **Block a co-author trailer.** A session-level attribution instruction can
  override a prose rule in CLAUDE.md. A PreToolUse(Bash) hook that greps the
  commit command for `Co-Authored-By: … claude|anthropic` and denies the call
  holds anyway. **(verified)**
- **Deny with JSON.** Instead of exit 2, print
  `{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"…"}}`.
  The reason reaches the model as the explanation. **(verified)**
- **Stop hooks that ask for follow-up work.** Print
  `{"decision":"block","reason":"…"}` and the model keeps going with that
  reason. **(verified)** Two variants:
  - **Doc coverage:** a manifest maps each doc to the paths it describes.
    Changed files newer than their doc (by mtime, so it works before any commit)
    trigger "update the doc, or say in one sentence why not". **(verified)**
  - **Sync reminder:** if there are uncommitted or unpushed changes, show them
    and ask the user. **(verified)**
- **One block per state, not per stop.** Store a signature of the problem (plus
  `HEAD`) in `$TMPDIR/<hook>/<session_id>` and stay silent if it hasn't
  changed. That prevents loops even where honouring `stop_hook_active` would be
  wrong, for example a sync check whose work happens in exactly that
  continuation. **(verified)**
- `timeout` and `statusMessage` per hook keep a slow check bounded and visible.
  **(practice)**
- **These hooks protect only sessions started in their repo.** A session started
  elsewhere that commits to this repo bypasses them, so the same rule also
  belongs in the user's memory or skill. **(docs: settings load from the start
  directory)**

## Loop guards

- A deterministic block plus a message that names the alternative usually ends
  the attempt at once. In a test the model stopped after one block, without
  trying a workaround. **(verified, n=1)**
- A **Stop** hook that exits 2 forces the model to continue. Check
  `stop_hook_active` in the input, or the loop never ends. **(docs, not tested)**
- Count blocks per `session_id` (it is in the hook's input). After N blocks, a JSON
  `{"continue": false, "stopReason": "…"}` should stop the session. **(docs, not
  tested; test it before relying on it)**
- Headless runs need a turn cap (`claude -p --max-turns`, SDK `maxTurns`) and a
  job timeout. **(docs)**
- Pipeline level: cap review rounds (say 3), then hand to a human. **(opinion)**
