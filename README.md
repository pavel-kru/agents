# agents

Patterns for running Claude Code agents on real codebases.

| File | What it answers |
|---|---|
| `claude-code/loading.md` | Which instruction files reach the model, and when |
| `claude-code/precedence.md` | What wins when instructions disagree (nothing built in) and a tie-break template |
| `claude-code/hooks.md` | Enforcing rules with hooks: what blocks, what slips through, loop guards |
| `claude-code/multi-repo.md` | Several repos in one session: siblings, `--add-dir`, nested clones, search |
| `claude-code/verification.md` | Proving what was loaded or enforced, using transcripts instead of the model's word |
| `claude-code/sharing.md` | Sharing knowledge across sessions, projects and machines: skills, overlays, sync |
| `instruction-design.md` | How to lay out CLAUDE.md, topic docs and rules so they stay true |
| `pipelines.md` | Multi-agent pipelines: hand-offs, isolation, parallel sessions, gates |
| `pitfalls.md` | Traps that cost real time, with the fix |
| `templates/` | CLAUDE.md skeleton (`CLAUDE.template.md`, never named CLAUDE.md here or it would load), hook + settings, a path-scoped rule |
| `scripts/transcript-inspect.mjs` | What a session actually loaded and did |
| `scripts/check-docs.mjs` | Session-start check that the cited docs haven't changed |
| `skills/agent-patterns/` | User skill that tells every session where these patterns live and how to add one |
| `install.sh` | Links `skills/*` into `~/.claude/skills` (`--check` to verify only) |
| `.claude/hooks/` | This repo's own hooks: commit approval, co-author block, doc coverage, sync reminder |

## Setup on a machine

```bash
git clone https://github.com/pavel-kru/agents.git ~/agents
~/agents/install.sh && ~/agents/install.sh --check
```
