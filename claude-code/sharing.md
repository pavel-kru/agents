---
sources:
  - https://code.claude.com/docs/en/skills.md
  - https://code.claude.com/docs/en/memory.md
  - https://code.claude.com/docs/en/settings.md
verified: 2026-10-22
claude_code: 2.1.303
---

# Sharing knowledge across sessions, projects and machines

## Pick the carrier by reach and cost

| Carrier | Reaches | Context cost | Enforced? |
|---|---|---|---|
| `~/.claude/CLAUDE.md` | every session on the machine | always loaded | no **(docs)** |
| user skill (`~/.claude/skills/<name>/`) | every session on the machine | description only; body on use | no **(docs)** |
| project skill (`<repo>/.claude/skills/`) | sessions started in that repo (or that touch it) | description only | no **(docs)** |
| auto memory (`~/.claude/projects/<path-slug>/memory/`) | sessions started at that one path | its index is loaded | no |
| project hooks / settings | sessions started in that repo | none | yes **(docs)** |
| plugin (marketplace + `enabledPlugins`) | every repo that enables it, the whole team | description only | hooks yes **(docs, not tested)** |

For "how to work with my patterns repo, from anywhere", use a **user skill**:
it reaches every session for the price of one description. **(opinion)** It is
installed here as `~/.claude/skills/agent-patterns`. **(verified: listed in the
transcript of a session started in an unrelated directory)**

## Write the description for the reader who won't open the skill

In a test the model took the repo path from the description and grepped the repo
directly, without invoking the skill. **(verified, n=1)** So:
- put **where** (paths) and **when** (triggers) in the description;
- put the procedure (steps, rules for contributing) in the body;
- keep anything that must hold, such as "don't commit unprompted", in hooks or
  in the user's memory as well, because a skill that is never invoked can't
  enforce it.

## Keep the skill in a repo, link it into place

The skill lives in a git repo, which gives it versioning, review and sync between
machines. An `install.sh` symlinks it into `~/.claude/skills/`. **(practice; see
`install.sh` here)**
- Re-runnable: replace an existing link, back up a real directory as `.bak`, and
  never clobber a local file.
- Prune links that point into the repo when their target is gone, or a deleted
  skill keeps being offered.
- Give it a `--check` mode (or a separate `verify.sh`) that changes nothing and
  exits non-zero. It should catch a real directory shadowing the link, a dangling
  link after the repo moved, and a link pointing elsewhere.

## Personal overlay on a team repo

To keep your own skills, hooks and notes for a team repo without committing them
to it **(practice)**:
- link `skills/`, `hooks/` and `settings.json` into the repo's `.claude/` when
  `.claude/` is gitignored there;
- for a file inside a **tracked** directory, add it to `.git/info/exclude`, not
  `.gitignore`: `.gitignore` is itself tracked, and `info/exclude` stays local;
- keep `settings.local.json` machine-local: seed an empty one, never symlink it;
- link memory files **one by one** into
  `~/.claude/projects/<path-slug>/memory/`. The slug comes from the project path
  (`/` becomes `-`), so compute it on each machine instead of hard-coding it.
  New memories need a re-run of the installer;
- add a **Stop hook that asks for sync**: it compares content between the repo
  and the live copies, finds uncommitted or unpushed work, and blocks once per
  state.

## Cross-machine rules

- `git pull` is the sync step, and nothing is pulled automatically. Pull before
  starting on the other machine.
- Claude rewrites memory files on its own, so the repo gains changes you didn't
  make. Two machines editing one memory between pulls will conflict.
