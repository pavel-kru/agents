---
sources: []
verified: 2026-10-21
claude_code: 2.1.303
---

# Pitfalls

**File upload tests hang under jsdom + MSW.** jsdom's `File` has no `stream()`.
MSW turns the XHR into a Node `Request`, and a multipart body built from a jsdom
`FormData`/`File` never finishes streaming, so the handler never answers. A Node
`File` doesn't help either: jsdom's `FormData` turns it into the string
`"[object File]"`. Fix: stub the upload call in that test. Real browsers are
fine. **(verified)**

**Symlinked `node_modules` in a worktree shares more than packages.** It also
shares the caches (`node_modules/.vite`, a `tsBuildInfoFile` under
`node_modules`). In one run the symlink disappeared mid-run, and 47 test files
failed to resolve imports. Give each worktree its own install (pnpm's shared
store keeps that cheap) and keep caches outside `node_modules`. **(verified)**

**`check && git commit && git push` in one command.** The commit goes out before
anyone reads the check output. Run the check, read it, then commit. **(verified)**

**Formatters rewrite front-matter.** Prettier turned double quotes into single
quotes in rule `paths:`. That's harmless (`claude-code/loading.md`), but test
after formatting, not before. **(verified)**

**Model self-reports.** "Was X loaded?" answers are often wrong. Read the
transcript instead (`claude-code/verification.md`). **(verified)**

**Hooks on macOS run under `/bin/bash` 3.2.** There is no `mapfile`, no
associative arrays, and `"${arr[@]}"` on an empty array fails under `set -u`.
File mtimes need GNU `stat -c %Y` on Linux and BSD `stat -f %m` on macOS. A hook
that breaks this exits non-zero, which Claude Code treats as a silent,
non-blocking error, so the check just never fires on the Mac. **(practice;
bash 3.2.57 verified on macOS)**

**Testing hooks from zsh.** zsh's `echo` expands `\n` inside JSON and produces
invalid input or output. Pipe JSON with `printf '%s'`. **(verified)**

**Allowlists can remove a decision point.** A `Bash(git commit *)` allow rule
meant commits never showed up as a prompt, and seven unreviewed commits landed.
Prefer a hook that asks the user over an allowlist entry. **(practice)**

**Case sensitivity.** macOS and Windows ignore case in paths, Linux doesn't. A
clone named `front` passes locally and breaks `../Front/...` paths on a Linux
runner. **(opinion)**

**PowerShell globs.** `git worktree repair C:\x\*` passes a literal `*` to git.
Expand it yourself: `(Get-ChildItem C:\x -Directory).FullName`. **(docs: PowerShell)**

**A failing provider API.** On repeated 5xx responses, check the provider's status
page before retrying or improvising around it, such as pushing straight to `main`.
**(opinion)**
